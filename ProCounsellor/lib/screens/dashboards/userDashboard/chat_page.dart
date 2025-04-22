import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_utils.dart';
import '../../../optimizations/api_cache.dart';
import '../userDashboard/Friends/UserToUserChattingPage.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'chatting_page.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final Future<void> Function() onSignOut;

  ChatPage({required this.userId, required this.onSignOut});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedTag = 'All';
  List<Map<String, dynamic>> allChats = [];
  List<Map<String, dynamic>> visibleChats = [];
  bool isLoading = true;
  int visibleLimit = 10;
  final ScrollController _scrollController = ScrollController();

  final List<StreamSubscription> _chatListeners = [];
  final String cacheKey = "chat_list_cache";
  final Map<String, Timer> _debounceTimers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCachedChats();
    fetchUserChatDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final sub in _chatListeners) {
      sub.cancel();
    }
    _debounceTimers.forEach((_, t) => t.cancel());
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered = List.from(allChats);

    if (selectedTag == 'Counsellors') {
      filtered = filtered.where((c) => c['role'] == 'counsellor').toList();
    } else if (selectedTag == 'Friends') {
      filtered = filtered.where((c) => c['role'] == 'user').toList();
    } else if (selectedTag == 'Unread') {
      filtered = filtered
          .where((c) => c['isSeen'] == false && c['senderId'] != widget.userId)
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = c['name']?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    }

    setState(() {
      visibleChats = filtered.take(visibleLimit).toList();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        visibleChats.length < allChats.length) {
      setState(() {
        visibleLimit += 10;
        visibleChats =
            allChats.take(visibleLimit.clamp(0, allChats.length)).toList();
      });
    }
  }

  Future<void> _loadCachedChats() async {
    final cachedData = await ApiCache.get(cacheKey);
    if (cachedData != null && mounted) {
      final cachedList = List<Map<String, dynamic>>.from(cachedData);
      setState(() {
        allChats = cachedList;
        visibleChats = cachedList.take(visibleLimit).toList();
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserChatDetails() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.userId}'));
      if (response.statusCode != 200 || response.body.isEmpty)
        throw Exception("Failed to fetch user");

      final data = json.decode(response.body);
      final chatIds =
          List<Map<String, dynamic>>.from(data['chatIdsCreatedForUser'] ?? []);
      List<Map<String, dynamic>> fetchedChats = [];

      for (final chat in chatIds) {
        final user2 = chat['user2'];
        final chatId = chat['chatId'];
        Map<String, dynamic>? chatInfo;

        chatInfo = await _getUserDetails(user2);
        chatInfo ??= await _getCounsellorDetails(user2);
        if (chatInfo == null) continue;

        chatInfo['chatId'] = chatId;

        try {
          final msgRes = await http
              .get(Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/messages'));
          if (msgRes.statusCode == 200) {
            final List<dynamic> messages = json.decode(msgRes.body);
            if (messages.isNotEmpty) {
              final lastMsg = messages.last;
              final timestamp = lastMsg['timestamp'];
              final isSeen = lastMsg['isSeen'] ?? true;
              final senderId = lastMsg['senderId'] ?? '';

              String lastMessageText = 'Media Message';
              if (lastMsg.containsKey('text') && lastMsg['text'] != null) {
                lastMessageText = lastMsg['text'];
              } else if (lastMsg.containsKey('fileType')) {
                final type = lastMsg['fileType'];
                if (type.startsWith('image/'))
                  lastMessageText = "📷 Image";
                else if (type.startsWith('video/'))
                  lastMessageText = "🎥 Video";
                else
                  lastMessageText = "📄 File";
              }

              chatInfo['lastMessage'] = lastMessageText;
              chatInfo['timestampRaw'] = timestamp;
              chatInfo['timestamp'] = DateFormat('dd MMM, h:mm a')
                  .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
              chatInfo['isSeen'] = isSeen;
              chatInfo['senderId'] = senderId;
              fetchedChats.add(chatInfo);
            }
          }
        } catch (_) {}

        //fetchedChats.add(chatInfo);
      }

      fetchedChats.sort((a, b) {
        final tsA = a['timestampRaw'] ?? 0;
        final tsB = b['timestampRaw'] ?? 0;
        return tsB.compareTo(tsA); // latest first
      });

      listenToRealtimeMessages(fetchedChats);
      await ApiCache.set(cacheKey, fetchedChats, persist: true);

      if (!mounted) return;
      setState(() {
        allChats = fetchedChats;
        visibleChats = fetchedChats.take(visibleLimit).toList();
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching chats: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    try {
      final res =
          await http.get(Uri.parse('${ApiUtils.baseUrl}/api/user/$userId'));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final user = json.decode(res.body);
        return {
          'userId': userId,
          'name': '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
          'photoUrl': user['photo'] ?? 'https://via.placeholder.com/150',
          'role': user['role'] ?? 'user',
        };
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _getCounsellorDetails(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiUtils.baseUrl}/api/counsellor/$userId'));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final counsellor = json.decode(res.body);
        return {
          'userId': userId,
          'name':
              '${counsellor['firstName'] ?? ''} ${counsellor['lastName'] ?? ''}',
          'photoUrl':
              counsellor['photoUrl'] ?? 'https://via.placeholder.com/150',
          'role': counsellor['role'] ?? 'counsellor',
        };
      }
    } catch (_) {}
    return null;
  }

  void listenToRealtimeMessages(List<Map<String, dynamic>> chatList) {
    for (final chat in chatList) {
      final chatId = chat['chatId'];
      final ref = FirebaseDatabase.instance.ref('chats/$chatId/messages');

      final sub1 = ref.onChildAdded.listen((event) {
        final msg = Map<String, dynamic>.from(event.snapshot.value as Map);
        _debouncedUpdate(chatId, msg);
      });

      final sub2 = ref.onChildChanged.listen((event) {
        final msg = Map<String, dynamic>.from(event.snapshot.value as Map);
        _debouncedUpdate(chatId, msg);
      });

      _chatListeners.addAll([sub1, sub2]);
    }
  }

  void _debouncedUpdate(String chatId, Map<String, dynamic> msg) {
    _debounceTimers[chatId]?.cancel();
    _debounceTimers[chatId] = Timer(Duration(milliseconds: 150), () {
      _updateChat(chatId, msg);
    });
  }

  void _updateChat(String chatId, Map<String, dynamic> msg) {
    final index = allChats.indexWhere((chat) => chat['chatId'] == chatId);
    if (index == -1) return;

    final chat = allChats[index];
    final timestamp = msg['timestamp'];
    final isSeen = msg['isSeen'] ?? true;
    final senderId = msg['senderId'] ?? '';

    String lastMessageText = 'Media Message';
    if (msg.containsKey('text') && msg['text'] != null) {
      lastMessageText = msg['text'];
    } else if (msg.containsKey('fileType')) {
      final type = msg['fileType'];
      if (type.startsWith('image/'))
        lastMessageText = "📷 Image";
      else if (type.startsWith('video/'))
        lastMessageText = "🎥 Video";
      else
        lastMessageText = "📄 File";
    }

    chat['lastMessage'] = lastMessageText;
    chat['timestampRaw'] = timestamp;
    chat['timestamp'] = DateFormat('dd MMM, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    chat['isSeen'] = isSeen;
    chat['senderId'] = senderId;

    allChats[index] = chat;
    allChats.sort((a, b) {
      final tsA = a['timestampRaw'] ?? 0;
      final tsB = b['timestampRaw'] ?? 0;
      return tsB.compareTo(tsA);
    });

    if (!mounted) return;
    setState(() {
      visibleChats = allChats.take(visibleLimit).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('My Chats')),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.deepOrangeAccent,
                size: 50,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, bottom: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'All',
                              'Counsellors',
                              'Friends',
                              'Unread'
                            ].map((label) {
                              final isSelected = selectedTag == label;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: Colors.deepOrangeAccent,
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      selectedTag = label;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.deepOrange[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleChats.isEmpty
                      ? Center(child: Text('No chats found'))
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: visibleChats.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.6,
                            color: Colors.grey.withOpacity(0.3),
                            indent: 70,
                            endIndent: 12,
                          ),
                          itemBuilder: (context, index) {
                            final chat = visibleChats[index];
                            final isMine = chat['senderId'] == widget.userId;
                            final lastMsg = isMine
                                ? "Me: ${chat['lastMessage']}"
                                : chat['lastMessage'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      NetworkImage(chat['photoUrl']),
                                  backgroundColor: Colors.grey[200],
                                ),
                                title: Text(
                                  chat['name'],
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastMsg ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      chat['timestamp'] ?? '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                                trailing: (chat['isSeen'] == false &&
                                        chat['senderId'] != widget.userId)
                                    ? Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  if (chat['role'] == 'user') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserToUserChattingPage(
                                                itemName: chat['userId'],
                                                userId: widget.userId,
                                                userId2: chat['userId'],
                                                onSignOut: () async {},
                                                role: "user"),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserToUserChattingPage(
                                          itemName: chat['userId'],
                                          userId: widget.userId,
                                          userId2: chat['userId'],
                                          onSignOut: () async {},
                                          role: "counsellor",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
