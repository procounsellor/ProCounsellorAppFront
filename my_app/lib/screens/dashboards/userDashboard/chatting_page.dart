import 'package:flutter/material.dart';
import 'chat_service.dart'; // Ensure MessageRequest class is available

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
  List<Map<String, dynamic>> messages = []; // Store full message objects
  TextEditingController _controller = TextEditingController();
  late String chatId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  Future<void> _startChat() async {
    try {
      chatId = await ChatService().startChat(widget.userId, widget.counsellorId)
          as String;
      setState(() {
        isLoading = false;
      });
      _loadMessages();
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
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      try {
        MessageRequest messageRequest = MessageRequest(
          senderId: widget.userId,
          text: _controller.text,
        );

        await ChatService().sendMessage(chatId, messageRequest);

        setState(() {
          messages.add({
            'senderId': widget.userId,
            'text': _controller.text,
          });
        });

        _controller.clear();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
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
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUserMessage =
                          message['senderId'] == widget.userId;

                      return Align(
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
                                ? Colors.blue[100]
                                : Colors.grey[300],
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
