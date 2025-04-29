import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_chatting_page.dart';
import '../userDashboard/Friends/UserToUserChattingPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main_service.dart';
import '../../../services/api_utils.dart';
import '../../../optimizations/api_cache.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final String counsellorId;
  final Future<void> Function() onSignOut;

  ChatPage({required this.counsellorId, required this.onSignOut});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> allChats = [];
  List<Map<String, dynamic>> visibleChats = [];
  List<StreamSubscription> _chatListeners = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, Timer> _debounceTimers = {};
  final TextEditingController _searchController = TextEditingController();
  final String cacheKey = 'counsellor_chat_cache';
  String selectedFilter = 'All';
  bool isLoading = true;
  int visibleLimit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearch);
    _loadCachedChats();
    _fetchChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    for (final sub in _chatListeners) {
      sub.cancel();
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        visibleChats.length < allChats.length) {
      setState(() {
        visibleLimit += 10;
        _applyFilters();
      });
    }
  }

  void _onSearch() {
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = allChats;

    if (selectedFilter != 'All') {
      filtered = filtered
          .where((chat) => chat['role'] == selectedFilter.toLowerCase())
          .toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((chat) => chat['name'].toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      visibleChats = filtered.take(visibleLimit).toList();
    });
  }

  Future<void> _loadCachedChats() async {
    final cached = await ApiCache.get(cacheKey);
    if (cached != null && mounted) {
      final list = List<Map<String, dynamic>>.from(json.decode(cached));
      setState(() {
        allChats = list;
        visibleChats = list.take(visibleLimit).toList();
        isLoading = false;
      });
      _listenToRealtimeMessages(allChats);
    }
  }

  Future<void> _fetchChats() async {
    try {
      final res = await http.get(Uri.parse(
          '${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}'));
      if (res.statusCode != 200) throw Exception('Failed to fetch chat list');

      final data = json.decode(res.body);
      final chatList = List<Map<String, dynamic>>.from(
          data['chatIdsCreatedForCounsellor'] ?? []);
      List<Map<String, dynamic>> fetchedChats = [];

      for (final chat in chatList) {
        final userId = chat['user2'];
        final chatId = chat['chatId'];

        final userRes =
            await http.get(Uri.parse('${ApiUtils.baseUrl}/api/user/$userId'));
        if (userRes.statusCode != 200) continue;

        final user = json.decode(userRes.body);
        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
        final photoUrl = user['photo'] ?? 'https://via.placeholder.com/150';
        final role = user['role'] ?? 'user';

        Map<String, dynamic> chatInfo = {
          'chatId': chatId,
          'userId': userId,
          'name': name,
          'photoUrl': photoUrl,
          'role': role,
        };

        try {
          final msgRes = await http
              .get(Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/messages'));
          if (msgRes.statusCode == 200) {
            final messages = json.decode(msgRes.body);
            //if (messages.isEmpty) continue;
            if (messages.isNotEmpty) {
              final last = messages.last;
              final ts = last['timestamp'];
              final senderId = last['senderId'] ?? '';
              final isSeen = last['isSeen'] ?? true;

              String text = last['text'] ?? 'Media';
              if (last['text'] == null && last['fileType'] != null) {
                final type = last['fileType'];
                text = type.startsWith('image/')
                    ? '📷 Image'
                    : type.startsWith('video/')
                        ? '🎥 Video'
                        : '📄 File';
              }

              if (senderId == widget.counsellorId) {
                text = "Me: $text";
              }

              chatInfo.addAll({
                'lastMessage': text,
                'timestampRaw': ts,
                'timestamp': DateFormat('dd MMM, h:mm a')
                    .format(DateTime.fromMillisecondsSinceEpoch(ts)),
                'isSeen': isSeen,
                'senderId': senderId,
              });
            } else {
              // No message yet → show "No messages yet!"
              chatInfo.addAll({
                'lastMessage': 'No messages yet!',
                'timestampRaw': 0, // No timestamp
                'timestamp': '', // No need to show date
                'isSeen': true,
                'senderId': '',
              });
            }
          }
        } catch (_) {}

        fetchedChats.add(chatInfo);
      }

      fetchedChats.sort((a, b) {
        final tsA = a['timestampRaw'] ?? 0;
        final tsB = b['timestampRaw'] ?? 0;
        return tsB.compareTo(tsA); // latest first
      });
      await ApiCache.set(cacheKey, json.encode(fetchedChats));

      if (!mounted) return;
      setState(() {
        allChats = fetchedChats;
        _applyFilters();
        isLoading = false;
      });

      _listenToRealtimeMessages(fetchedChats);
    } catch (e) {
      print("❌ Chat fetch error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _listenToRealtimeMessages(List<Map<String, dynamic>> chats) {
    for (final chat in chats) {
      final chatId = chat['chatId'];
      final ref = FirebaseDatabase.instance.ref('chats/$chatId/messages');

      final sub1 =
          ref.onChildAdded.listen((e) => _debouncedUpdate(chatId, e.snapshot));
      final sub2 = ref.onChildChanged
          .listen((e) => _debouncedUpdate(chatId, e.snapshot));

      _chatListeners.addAll([sub1, sub2]);
    }
  }

  void _debouncedUpdate(String chatId, DataSnapshot snap) {
    _debounceTimers[chatId]?.cancel();
    _debounceTimers[chatId] =
        Timer(Duration(milliseconds: 150), () => _updateChat(chatId, snap));
  }

  void _updateChat(String chatId, DataSnapshot snapshot) {
    if (!mounted) return;

    final msg = Map<String, dynamic>.from(snapshot.value as Map);
    final index = allChats.indexWhere((c) => c['chatId'] == chatId);
    if (index == -1) return;

    final chat = allChats[index];
    final ts = msg['timestamp'];
    final senderId = msg['senderId'] ?? '';
    final isSeen = msg['isSeen'] ?? true;

    String text = msg['text'] ?? 'Media';
    if (msg['text'] == null && msg['fileType'] != null) {
      final type = msg['fileType'];
      text = type.startsWith('image/')
          ? '📷 Image'
          : type.startsWith('video/')
              ? '🎥 Video'
              : '📄 File';
    }

    if (senderId == widget.counsellorId) {
      text = "Me: $text";
    }

    chat['lastMessage'] = text;
    chat['timestampRaw'] = ts;
    chat['timestamp'] = DateFormat('dd MMM, h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(ts));
    chat['isSeen'] = isSeen;
    chat['senderId'] = senderId;

    allChats[index] = chat;

    // Sort the whole list again
    allChats.sort(
        (a, b) => (b['timestampRaw'] ?? 0).compareTo(a['timestampRaw'] ?? 0));

    _applyFilters(); // this respects sort order
  }

  // void _updateChat(String chatId, DataSnapshot snapshot) {
  //   if (!mounted) return;
  //   final msg = Map<String, dynamic>.from(snapshot.value as Map);
  //   final index = allChats.indexWhere((c) => c['chatId'] == chatId);
  //   if (index == -1) return;

  //   final chat = allChats[index];
  //   final ts = msg['timestamp'];
  //   final senderId = msg['senderId'] ?? '';
  //   final isSeen = msg['isSeen'] ?? true;

  //   String text = msg['text'] ?? 'Media';
  //   if (msg['text'] == null && msg['fileType'] != null) {
  //     final type = msg['fileType'];
  //     text = type.startsWith('image/')
  //         ? '📷 Image'
  //         : type.startsWith('video/')
  //             ? '🎥 Video'
  //             : '📄 File';
  //   }

  //   if (senderId == widget.counsellorId) {
  //     text = "Me: $text";
  //   }

  //   chat['lastMessage'] = text;
  //   chat['timestampRaw'] = ts;
  //   chat['timestamp'] = DateFormat('dd MMM, h:mm a')
  //       .format(DateTime.fromMillisecondsSinceEpoch(ts));
  //   chat['isSeen'] = isSeen;
  //   chat['senderId'] = senderId;

  //   allChats.removeAt(index);
  //   allChats.insert(0, chat);

  //   _applyFilters();
  // }

  Widget buildFilterChips() {
    const options = ['All', 'Friends', 'Counsellors'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Wrap(
        spacing: 8,
        children: options
            .map(
              (filter) => ChoiceChip(
                label: Text(filter),
                selected: selectedFilter == filter,
                selectedColor: Colors.orangeAccent,
                onSelected: (_) {
                  setState(() {
                    selectedFilter = filter;
                    _applyFilters();
                  });
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "My Chats",
          style: GoogleFonts.outfit(
            // 👈 or any font like Roboto, Lato, Poppins
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black, // since background is white
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.deepOrange, size: 50))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name...",
                      filled: true,
                      fillColor: Colors.orangeAccent.withOpacity(0.1),
                      prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                //  buildFilterChips(),
                Expanded(
                  child: visibleChats.isEmpty
                      ? Center(child: Text("No chats found"))
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: visibleChats.length,
                          separatorBuilder: (_, __) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(
                              color: Colors.grey
                                  .withOpacity(0.3), // lighter and subtle
                              thickness: 0.6, // thinner than default
                              height: 20, // adds spacing vertically
                            ),
                          ),
                          itemBuilder: (context, i) {
                            final chat = visibleChats[i];
                            return ListTile(
                              leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(chat['photoUrl'])),
                              title: Text(chat['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(chat['lastMessage'] ?? '',
                                      overflow: TextOverflow.ellipsis),
                                  Text(chat['timestamp'] ?? '',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: (chat['isSeen'] == false &&
                                      chat['senderId'] != widget.counsellorId)
                                  ? Icon(Icons.circle,
                                      size: 10, color: Colors.blue)
                                  : null,
                              onTap: () async {
                                MainService _mainService = MainService();
                                final user = await _mainService
                                    .getUserFromUserId(chat['userId']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CounsellorChattingPage(
                                      itemName: chat['name'],
                                      userId: chat['userId'],
                                      photo: user['photo'],
                                      counsellorId: widget.counsellorId,
                                      onSignOut: widget.onSignOut,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
