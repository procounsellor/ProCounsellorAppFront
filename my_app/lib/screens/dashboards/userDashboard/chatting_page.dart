import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'chat_service.dart';
import 'dart:convert'; // For JSON decoding
import 'details_page.dart'; // Import CounsellorDetailsPage

class ChattingPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;

  ChattingPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
  });

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController _controller = TextEditingController();
  late String chatId;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool showSendButton = false;

  // For counsellor's online status
  String counsellorPhotoUrl = 'https://via.placeholder.com/150';
  bool isCounsellorOnline = false;
  late DatabaseReference counsellorStateRef;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _listenToCounsellorStatus();
  }

  Future<void> _initializeChat() async {
    await _startChat();
    if (!isLoading) {
      _listenForNewMessages();
      _listenForSeenStatusUpdates();
    }
  }

  Future<void> _startChat() async {
    try {
      chatId = await ChatService().startChat(widget.userId, widget.counsellorId)
          as String;

      // Fetch counsellor's profile data
      await _fetchCounsellorProfile();

      setState(() {
        isLoading = false;
      });
      _loadMessages();
    } catch (e) {
      print('Error starting chat: $e');
    }
  }

  Future<void> _fetchCounsellorProfile() async {
    try {
      String url =
          'http://localhost:8080/api/counsellor/${widget.counsellorId}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        setState(() {
          counsellorPhotoUrl = data['photoUrl'] ?? counsellorPhotoUrl;
        });
      }
    } catch (e) {
      print('Error fetching counsellor profile: $e');
    }
  }

  void _listenToCounsellorStatus() {
    counsellorStateRef = FirebaseDatabase.instance
        .ref('counsellorStates/${widget.counsellorId}');

    counsellorStateRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          isCounsellorOnline = data['state'] == 'online';
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      List<Map<String, dynamic>> fetchedMessages =
          await ChatService().getChatMessages(chatId);
      setState(() {
        messages = fetchedMessages;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _listenForNewMessages() {
    ChatService().listenForNewMessages(chatId, (newMessages) {
      if (mounted) {
        setState(() {
          for (var message in newMessages) {
            if (!messages.any(
                (existingMessage) => existingMessage['id'] == message['id'])) {
              messages.add(message);
              if (message['senderId'] == widget.counsellorId) {
                _markMessageAsSeen(message['id']);
              }
            }
          }
          _scrollToBottom();
        });
      }
    });
  }

  void _listenForSeenStatusUpdates() {
    ChatService().listenForSeenStatusUpdates(chatId, (updatedMessages) {
      if (mounted) {
        setState(() {
          for (var updatedMessage in updatedMessages) {
            for (var message in messages) {
              if (message['id'] == updatedMessage['id']) {
                message['isSeen'] = updatedMessage['isSeen'];
              }
            }
          }
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      try {
        MessageRequest messageRequest = MessageRequest(
          senderId: widget.userId,
          text: _controller.text,
        );

        await ChatService().sendMessage(chatId, messageRequest);

        _controller.clear();
        setState(() {
          showSendButton = false;
        });
        _scrollToBottom();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessageAsSeen(String messageId) async {
    try {
      String url =
          'http://localhost:8080/api/chats/$chatId/messages/$messageId/mark-seen';
      final response = await http.post(Uri.parse(url));
      if (response.statusCode != 200) {
        print('Failed to mark message $messageId as seen: ${response.body}');
      }
    } catch (e) {
      print('Error marking message $messageId as seen: $e');
    }
  }

  @override
  void dispose() {
    ChatService().cancelListeners(chatId);
    counsellorStateRef.onDisconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsPage(
                      counsellorId: widget.counsellorId,
                      userId: widget.userId,
                      itemName: widget.counsellorId,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(counsellorPhotoUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor:
                            isCounsellorOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Text(
              widget.itemName,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isUserMessage =
                          message['senderId'] == widget.userId;
                      final isLastMessage = index == 0;

                      return Column(
                        crossAxisAlignment: isUserMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: isUserMessage
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 5.0,
                                horizontal: 10.0,
                              ),
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: isUserMessage
                                    ? Colors.orangeAccent.withOpacity(0.2)
                                    : Colors.blueGrey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                message['text'] ?? 'No message',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                          if (isLastMessage &&
                              isUserMessage &&
                              message['isSeen'] == true)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Text(
                                'Seen',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.black54),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (text) {
                            setState(() {
                              showSendButton = text.isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 10.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.black54),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.black54),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          showSendButton ? Icons.send : Icons.mic,
                          color: Colors.black54,
                        ),
                        onPressed: showSendButton ? _sendMessage : () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
