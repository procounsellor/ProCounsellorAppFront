import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:http/http.dart' as http; // For API calls
import 'package:ProCounsellor/screens/customWidgets/video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_utils.dart';
import '../../../services/chat_service.dart';
import 'client_details_page.dart'; // Import the Client Details Page
import 'package:shared_preferences/shared_preferences.dart';

class ChattingPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final String? photo;
  final Future<void> Function() onSignOut;

  ChattingPage(
      {required this.itemName,
      required this.userId,
      required this.counsellorId,
      this.photo,
      required this.onSignOut});

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

  File? selectedFile; // Store selected file
  String? selectedFileName; // Store file name
  Uint8List? webFileBytes; // For Web

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
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load cached messages first
      String? cachedData = prefs.getString('chat_cache_$chatId');
      if (cachedData != null) {
        List decoded = jsonDecode(cachedData);
        setState(() {
          messages = List<Map<String, dynamic>>.from(decoded);
        });
      }

      // Fetch from backend
      List<Map<String, dynamic>> fetchedMessages =
          await ChatService().getChatMessages(chatId);

      setState(() {
        messages = fetchedMessages;
      });

      // Save to cache
      prefs.setString('chat_cache_$chatId', jsonEncode(fetchedMessages));

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _markMessageAsSeen(String messageId) async {
    try {
      String url =
          '${ApiUtils.baseUrl}/api/chats/$chatId/messages/$messageId/mark-seen';
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

  // Function to open the bottom sheet
  void _showFileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(15),
          height: 180,
          child: Column(
            children: [
              Text(
                "Select File Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _fileOption("Image", Icons.image, () {
                    _pickFile(FileType.image);
                    Navigator.pop(context);
                  }),
                  _fileOption("Video", Icons.video_library, () {
                    _pickFile(FileType.video);
                    Navigator.pop(context);
                  }),
                  _fileOption("File", Icons.insert_drive_file, () {
                    _pickFile(FileType.custom, allowedExtensions: [
                      'pdf',
                      'doc',
                      'docx',
                      'xls',
                      'xlsx',
                      'ppt',
                      'pptx',
                      'txt'
                    ]);
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for each file option
  Widget _fileOption(String label, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueGrey.withOpacity(0.2),
            child: Icon(icon, size: 30, color: Colors.black),
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<void> _pickFile(FileType type,
      {List<String>? allowedExtensions}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: true, // Ensures bytes are available for web
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;

        if (kIsWeb) {
          // Web: Store file bytes
          webFileBytes = result.files.single.bytes;
          selectedFile = null; // No File object on web
        } else {
          // Mobile/Desktop: Store file path
          selectedFile = File(result.files.single.path!);
          webFileBytes = null;
        }
        showSendButton = true;
      });
      print("Selected File: $selectedFileName");
    }
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
        setState(() {
          showSendButton = selectedFile != null || webFileBytes != null;
        });
        _scrollToBottom();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  Future<void> _sendFileMessage() async {
    if (selectedFile != null || webFileBytes != null) {
      int fileSizeBytes = 0;

      // 🔥 Check for file size before uploading
      if (selectedFile != null) {
        fileSizeBytes = await selectedFile!.length();
      } else if (webFileBytes != null) {
        fileSizeBytes = webFileBytes!.length;
      }

      // ✅  Set your max size (e.g., 15MB)
      const maxSizeInBytes = 10 * 1024 * 1024;

      if (fileSizeBytes > maxSizeInBytes) {
        _showErrorDialog("File too large",
            "This file exceeds the 10MB limit. Please choose a smaller file.");
        return; // ❌ Don't proceed with upload
      }
      // Create a temporary message to show in the UI immediately
      Map<String, dynamic> tempMessage = {
        'id': 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
        'senderId': widget.counsellorId,
        'fileName': selectedFileName,
        'fileUrl': null, // No URL yet (file not uploaded)
        'fileType': 'uploading', // Temporary "uploading" status
        'isSeen': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Add the file message to UI instantly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            messages.add(tempMessage);
          });
          _scrollToBottom();
        }
      });

      // Save a copy of the selected file details
      File? tempFile = selectedFile;
      Uint8List? tempWebBytes = webFileBytes;
      String tempFileName = selectedFileName!;

      // Clear the selected file immediately
      setState(() {
        selectedFile = null;
        selectedFileName = null;
        webFileBytes = null;
        showSendButton = _controller.text.isNotEmpty;
      });

      try {
        // Upload file to the backend
        await ChatService.sendFileMessage(
          chatId: chatId,
          senderId: widget.counsellorId,
          file: tempFile,
          webFileBytes: tempWebBytes,
          fileName: tempFileName,
        );

        print("✅ File uploaded successfully!");

        // Fetch updated messages from backend and replace the temporary message
        _loadMessages(); // Refresh messages immediately
      } catch (e) {
        print("❌ Error sending file: $e");

        // Remove the temporary message if an error occurs
        setState(() {
          messages.remove(tempMessage);
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
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

  Widget _buildImageMessage(Map<String, dynamic> message) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                message['fileUrl'],
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          message['fileUrl'],
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error, color: Colors.red);
          },
        ),
      ),
    );
  }

  Widget _buildVideoMessage(Map<String, dynamic> message) {
    if (kIsWeb) {
      // On Web, open video in a new browser tab
      return GestureDetector(
        onTap: () {
          _launchURL(message['fileUrl']);
        },
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
            ],
          ),
        ),
      );
    } else {
      // Mobile/Desktop: Show video preview and play inside the app
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              child: VideoPlayerWidget(videoUrl: message['fileUrl']),
            ),
          );
        },
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
            ],
          ),
        ),
      );
    }
  }

// Open Video in Browser on Web
  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }

  Widget _buildFileMessage(Map<String, dynamic> message) {
    return GestureDetector(
      onTap: () {
        _downloadFile(message['fileUrl']);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, color: Colors.black),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message['fileName'] ?? "Unknown file",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.download, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  void _downloadFile(String url) async {
    Uri uri = Uri.parse(url); // Convert string to Uri

    print("Downloading file from: $url");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }

  Widget _buildMessageWidget(Map<String, dynamic> message) {
    if (message['fileUrl'] != null || message['fileType'] == 'uploading') {
      String fileType = message['fileType'] ?? 'unknown';

      if (fileType == 'uploading') {
        return _buildUploadingFileMessage(message);
      } else if (fileType.startsWith('image/')) {
        return _buildImageMessage(message);
      } else if (fileType.startsWith('video/')) {
        return _buildVideoMessage(message);
      } else {
        return _buildFileMessage(message);
      }
    }

    return Text(
      message['text'] ?? 'No message',
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
    );
  }

  Widget _buildUploadingFileMessage(Map<String, dynamic> message) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.upload, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message['fileName'] ?? "Uploading...",
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CircularProgressIndicator(),
        ],
      ),
    );
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
                  onSignOut: widget.onSignOut,
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
                            child: _buildMessageWidget(message),
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
                if (selectedFileName != null) // Show selected file
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.black54),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                              selectedFileName = null;
                              webFileBytes = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.black54),
                        onPressed: () => _showFileOptions(context),
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
                                showSendButton = text.isNotEmpty ||
                                    selectedFile != null ||
                                    webFileBytes != null;
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
                        onPressed: showSendButton
                            ? () {
                                if (_controller.text.isNotEmpty) _sendMessage();
                                if (selectedFile != null ||
                                    webFileBytes != null) _sendFileMessage();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
