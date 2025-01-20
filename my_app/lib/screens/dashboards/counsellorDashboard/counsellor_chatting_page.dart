import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:http/http.dart' as http; // For API calls
import '../userDashboard/chat_service.dart';
import 'client_details_page.dart'; // Import the Client Details Page

class ChattingPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final String? photo; // Allow photo to be nullable

  ChattingPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
    this.photo,
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
  bool showSendButton = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _startChat();
    if (!isLoading) {
      await _loadMessages();
      _markUnreadMessagesAsSeen();
      _listenForNewMessages();
      _listenForSeenStatusUpdates();
      _listenForIsSeenChanges();
    }
  }

  Future<void> _startChat() async {
    try {
      chatId = await ChatService().startChat(widget.userId, widget.counsellorId)
          as String;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error starting chat: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      List<Map<String, dynamic>> fetchedMessages =
          await ChatService().getChatMessages(chatId);
      setState(() {
        messages = fetchedMessages
            .map((msg) => Map<String, dynamic>.from(msg))
            .toList(); // Convert each message
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
      if (response.statusCode != 200) {
        print('Failed to mark message $messageId as seen: ${response.body}');
      }
    } catch (e) {
      print('Error marking message $messageId as seen: $e');
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

  void _listenForIsSeenChanges() {
    final databaseReference =
        FirebaseDatabase.instance.ref('chats/$chatId/messages');
    databaseReference.onChildChanged.listen((event) {
      final updatedMessage = Map<String, dynamic>.from(
          event.snapshot.value as Map); // Ensure conversion
      final messageId = updatedMessage['id'];
      final isSeen = updatedMessage['isSeen'];

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

  Stream<String> getUserState(String userId) {
    final databaseReference =
        FirebaseDatabase.instance.ref('userStates/$userId/state');
    return databaseReference.onValue.map((event) {
      final state = event.snapshot.value as String?;
      return state ?? 'offline'; // Default to 'offline' if null
    });
  }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientDetailsPage(
                  client: {
                    'firstName': widget.itemName.split(' ')[0],
                    'lastName': widget.itemName.split(' ').length > 1
                        ? widget.itemName.split(' ')[1]
                        : '',
                    'email': widget.itemName,
                    'phone': '',
                    'photo': widget.photo ?? '',
                    'userName': widget.userId,
                  },
                  counsellorId: widget.counsellorId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.photo ?? ''),
                    radius: 24,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: StreamBuilder<String>(
                      stream: getUserState(widget.userId),
                      builder: (context, snapshot) {
                        final state = snapshot.data ?? 'offline';
                        return CircleAvatar(
                          radius: 6,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor:
                                state == 'online' ? Colors.green : Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.itemName.isNotEmpty ? widget.itemName : 'Unknown User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
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

                      return Column(
                        crossAxisAlignment: isUserMessage
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 5.0,
                              horizontal: 10.0,
                            ),
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: isUserMessage
                                  ? Colors.grey[300]
                                  : Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              message['text'] ??
                                  'No message', // Fallback for empty message
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          if (index == messages.length - 1 &&
                              isCounsellorMessage &&
                              message['isSeen'] == true)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 2.0, right: 16.0),
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
                      if (!showSendButton)
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.black54),
                          onPressed: () {},
                        ),
                      if (!showSendButton)
                        IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.black54),
                          onPressed: () {},
                        ),
                      if (!showSendButton)
                        IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.black54),
                          onPressed: () {},
                        ),
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: showSendButton
                              ? MediaQuery.of(context).size.width * 0.8
                              : MediaQuery.of(context).size.width * 0.65,
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
