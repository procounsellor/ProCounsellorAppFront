import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'chatting_page.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String userId;

  ChatPage({required this.userId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh chats when coming back to this page
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:8080/api/user/${widget.userId}/subscribed-counsellors'));

      if (response.statusCode == 200) {
        final List<dynamic> counsellors = json.decode(response.body);
        List<Map<String, dynamic>> chatDetails = [];

        for (var counsellor in counsellors) {
          final counsellorId = counsellor['userName'];
          final counsellorName =
              counsellor['firstName'] ?? 'Unknown Counsellor';
          final counsellorPhotoUrl =
              counsellor['photoUrl'] ?? 'https://via.placeholder.com/150';

          // Fetch or initialize chat ID
          final chatResponse = await http.post(
            Uri.parse(
                'http://localhost:8080/api/chats/start-chat?userId=${widget.userId}&counsellorId=$counsellorId'),
          );

          if (chatResponse.statusCode == 200) {
            final chatData = json.decode(chatResponse.body);
            final chatId = chatData['chatId'];

            // Fetch messages for the chat
            final messagesResponse = await http.get(
              Uri.parse('http://localhost:8080/api/chats/$chatId/messages'),
            );

            if (messagesResponse.statusCode == 200) {
              final messages =
                  json.decode(messagesResponse.body) as List<dynamic>;
              final lastMessage = messages.isNotEmpty
                  ? messages.last['text']
                  : 'No messages yet';
              final timestamp = messages.isNotEmpty
                  ? DateFormat('dd MMM yyyy, h:mm a').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          messages.last['timestamp']),
                    )
                  : 'N/A';
              final isSeen =
                  messages.isNotEmpty ? messages.last['isSeen'] : true;

              final senderId = messages.last['senderId'];

              chatDetails.add({
                'id': chatId,
                'counsellorId': counsellorId,
                'name': counsellorName,
                'photoUrl': counsellorPhotoUrl,
                'lastMessage': lastMessage,
                'timestamp': timestamp,
                'isSeen': isSeen,
                'senderId': senderId,
              });
            }
          }
        }

        setState(() {
          chats = chatDetails;
          filteredChats = chatDetails;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch subscribed counsellors");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void filterChats(String query) {
    setState(() {
      searchQuery = query;
      filteredChats = chats
          .where((chat) => chat['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  Stream<String> getCounsellorState(String counsellorId) {
    final databaseReference =
        FirebaseDatabase.instance.ref('counsellorStates/$counsellorId/state');
    return databaseReference.onValue
        .map((event) => event.snapshot.value as String? ?? 'offline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Chats"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterChats,
              decoration: InputDecoration(
                hintText: "Search counsellors...",
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                fillColor: Color(0xFFFFF3E0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredChats.isEmpty
                    ? Center(child: Text("No chats available"))
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          indent: 10,
                          endIndent: 10,
                        ),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final name = chat['name'] ?? 'Unknown Counsellor';
                          final photoUrl = chat['photoUrl'];
                          final counsellorId = chat['counsellorId'];
                          final lastMessage = chat['lastMessage'];
                          final timestamp = chat['timestamp'];
                          final isSeen = chat['isSeen'];
                          final senderId = chat['senderId'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChattingPage(
                                    itemName: name,
                                    userId: widget.userId,
                                    counsellorId: counsellorId,
                                  ),
                                ),
                              ).then((_) {
                                fetchChats(); // Refresh chats on returning
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundImage: NetworkImage(photoUrl),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: StreamBuilder<String>(
                                          stream:
                                              getCounsellorState(counsellorId),
                                          builder: (context, snapshot) {
                                            final state =
                                                snapshot.data ?? 'offline';
                                            return CircleAvatar(
                                              radius: 8,
                                              backgroundColor: Colors.white,
                                              child: CircleAvatar(
                                                radius: 6,
                                                backgroundColor:
                                                    state == 'online'
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              timestamp,
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lastMessage,
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isSeen &&
                                                senderId != widget.userId)
                                              Icon(
                                                Icons.circle,
                                                color: Colors.blue,
                                                size: 10,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
