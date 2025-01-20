import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'counsellor_chatting_page.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatsPage extends StatefulWidget {
  final String counsellorId;

  ChatsPage({required this.counsellorId});

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients'));

      if (response.statusCode == 200) {
        final List<dynamic> clients = json.decode(response.body);
        List<Map<String, dynamic>> chatDetails = [];

        for (var client in clients) {
          final userId = client['userName'];
          final clientName = "${client['firstName']} ${client['lastName']}";
          final clientPhotoUrl =
              client['photo'] ?? 'https://via.placeholder.com/150';

          // Check if chat exists
          final chatExistsResponse = await http.get(Uri.parse(
              'http://localhost:8080/api/chats/exists?userId=$userId&counsellorId=${widget.counsellorId}'));

          if (chatExistsResponse.statusCode == 200 &&
              json.decode(chatExistsResponse.body) == true) {
            // Fetch chat details
            final chatResponse = await http.post(Uri.parse(
                'http://localhost:8080/api/chats/start-chat?userId=$userId&counsellorId=${widget.counsellorId}'));

            if (chatResponse.statusCode == 200) {
              final chatData = json.decode(chatResponse.body);
              final chatId = chatData['chatId'];

              // Fetch messages
              final messagesResponse = await http.get(
                Uri.parse('http://localhost:8080/api/chats/$chatId/messages'),
              );

              if (messagesResponse.statusCode == 200) {
                final messages =
                    json.decode(messagesResponse.body) as List<dynamic>;

                String lastMessage = 'No messages yet';
                String timestamp = 'N/A';
                bool isSeen = true;
                String senderId = '';

                if (messages.isNotEmpty) {
                  lastMessage = messages.last['text'] ?? 'No message';
                  timestamp = DateFormat('dd MMM yyyy, h:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(
                        messages.last['timestamp']),
                  );
                  isSeen = messages.last['isSeen'] ?? true;
                  senderId = messages.last['senderId'] ?? '';
                }

                chatDetails.add({
                  'id': chatId,
                  'userId': userId,
                  'name': clientName,
                  'photoUrl': clientPhotoUrl,
                  'lastMessage': lastMessage,
                  'timestamp': timestamp,
                  'isSeen': isSeen,
                  'senderId': senderId,
                });
              }
            }
          }
        }

        setState(() {
          chats = chatDetails;
          filteredChats = chatDetails;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch chatting clients");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                hintText: "Search clients...",
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
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.deepOrangeAccent,
                      size: 50,
                    ),
                  )
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
                          final name = chat['name'] ?? 'Unknown Client';
                          final photoUrl = chat['photoUrl'];
                          final userId = chat['userId'];
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
                                    userId: userId,
                                    counsellorId: widget.counsellorId,
                                    photo: photoUrl,
                                  ),
                                ),
                              ).then((_) {
                                fetchChats(); // Refresh chats after returning
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(photoUrl),
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
                                                senderId != widget.counsellorId)
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
