import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:http/http.dart' as http; // For API calls
import '../userDashboard/chat_service.dart';

class ChattingPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final String photo;

  ChattingPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
    required this.photo,
  });

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  List<Map<String, dynamic>> messages = []; // Store full message objects
  TextEditingController _controller = TextEditingController();
  late String chatId;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('Initializing chat...');
    await _startChat();
    if (!isLoading) {
      print('Chat initialized, loading messages...');
      await _loadMessages(); // Ensure messages are loaded
      _markUnreadMessagesAsSeen(); // Mark unread messages as seen when the page is opened
      _listenForNewMessages(); // Set up listener for new messages
      _listenForSeenStatusUpdates();
      _listenForIsSeenChanges(); // Listen for changes in the 'isSeen' flag
    } else {
      print('Chat is still loading.');
    }
  }

  Future<void> _startChat() async {
    try {
      chatId = await ChatService().startChat(widget.userId, widget.counsellorId)
          as String;
      setState(() {
        isLoading = false;
      });
      print('Chat started successfully with chatId: $chatId');
    } catch (e) {
      print('Error starting chat: $e');
    }
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

  Future<void> _markMessageAsSeen(String messageId) async {
    try {
      String url =
          'http://localhost:8080/api/chats/$chatId/messages/$messageId/mark-seen';

      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
      } else {
        print('Failed to mark message $messageId as seen: ${response.body}');
      }
    } catch (e) {
      print('Error marking message $messageId as seen: $e');
    }
  }

  // Real-time listener for new messages
  void _listenForNewMessages() {
    ChatService().listenForNewMessages(chatId, (newMessages) {
      if (mounted) {
        setState(() {
          for (var message in newMessages) {
            if (!messages.any(
                (existingMessage) => existingMessage['id'] == message['id'])) {
              messages.add(message);
              // Mark the newly received message as seen
              if (message['senderId'] == widget.userId) {
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
          // Update the 'isSeen' status of the messages
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

  // Listen for real-time changes in the 'isSeen' flag of counsellor's messages
  void _listenForIsSeenChanges() {
    final databaseReference =
        FirebaseDatabase.instance.ref('chats/$chatId/messages');

    databaseReference.onChildChanged.listen((event) {
      final updatedMessage = event.snapshot.value as Map<String, dynamic>;
      final messageId = updatedMessage['id'];
      final isSeen = updatedMessage['isSeen'];

      // Update the UI if the isSeen flag changes for a counsellor's message
      setState(() {
        for (var message in messages) {
          if (message['id'] == messageId &&
              message['senderId'] == widget.counsellorId) {
            message['isSeen'] = isSeen;
          }
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      try {
        MessageRequest messageRequest = MessageRequest(
          senderId: widget.counsellorId,
          text: _controller.text,
        );

        await ChatService().sendMessage(chatId, messageRequest);

        _controller.clear();
        _scrollToBottom();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Method to fetch user online/offline status from Firebase
  Stream<String> getUserState(String userId) {
    final databaseReference =
        FirebaseDatabase.instance.ref('userStates/$userId/state');
    return databaseReference.onValue
        .map((event) => event.snapshot.value as String);
  }

  // Mark all unread messages as seen when the page is opened
  Future<void> _markUnreadMessagesAsSeen() async {
    try {
      for (var message in messages) {
        if (message['state'] != 'seen' &&
            message['senderId'] == widget.userId) {
          String messageId = message['id'];
          await _markMessageAsSeen(messageId);
        }
      }
    } catch (e) {
      print('Error marking unread messages as seen: $e');
    }
  }

  @override
  void dispose() {
    ChatService().cancelListeners(chatId);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.itemName}"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Client's Profile Photo and Online/Offline Indicator
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          widget.photo, // Replace with actual photo URL
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(widget.itemName),
                      SizedBox(width: 10),
                      StreamBuilder<String>(
                        // User state (online/offline)
                        stream: getUserState(widget.userId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final state = snapshot.data;
                            return CircleAvatar(
                              radius: 6,
                              backgroundColor:
                                  state == 'online' ? Colors.green : Colors.red,
                            );
                          }
                          return CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.grey,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUserMessage =
                          message['senderId'] == widget.userId;
                      final isCounsellorMessage =
                          message['senderId'] == widget.counsellorId;

                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 10.0,
                          ),
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? Colors.grey[300]
                                : Colors.blue[100],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'] ?? 'No message',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                              // Show 'Seen' indicator for counsellor's messages
                              if (isCounsellorMessage &&
                                  message['isSeen'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    'Seen',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) =>
                              _sendMessage(), // Handle Enter key
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
