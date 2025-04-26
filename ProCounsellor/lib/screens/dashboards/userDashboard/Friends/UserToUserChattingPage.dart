import 'dart:async';
import 'dart:io';
import 'package:ProCounsellor/screens/newCallingScreen/save_fcm_token.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:ProCounsellor/screens/customWidgets/video_player_widget.dart';
import '../../../../services/api_utils.dart';
import 'ChatServiceUserToUser.dart';
//import '../../../../services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_details_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../userDashboard/details_page.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:media_scanner/media_scanner.dart';
import 'package:exif/exif.dart';

import 'dart:math';

import 'dart:typed_data';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_sound/flutter_sound.dart';

import 'package:flutter/services.dart';

class UserToUserChattingPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String userId2;
  final Future<void> Function() onSignOut;
  final String role;

  UserToUserChattingPage(
      {required this.itemName,
      required this.userId,
      required this.userId2,
      required this.onSignOut,
      required this.role});

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<UserToUserChattingPage> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController _controller = TextEditingController();
  late String chatId;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool showSendButton = false;

  bool isTyping = false;
  final FocusNode _focusNode = FocusNode();

  // For counsellor's online status
  String counsellorPhotoUrl = 'https://via.placeholder.com/150';
  bool isCounsellorOnline = false;
  late DatabaseReference counsellorStateRef;

  File? selectedFile; // Store selected file
  String? selectedFileName; // Store file name
  Uint8List? webFileBytes; // For Web

  // for user details
  String userPhotoUrl = 'https://via.placeholder.com/150';
  String userFirstName = '';
  String userLastName = '';

  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  FlutterSoundRecorder? _audioRecorder;
  bool isRecording = false;
  String? audioPath; // Store path of recorded file

  FlutterSoundPlayer? _audioPlayer;
  bool isPlaying = false;
  Map<String, bool> playingStates = {};
  Map<String, List<double>> waveformHeights = {};
  Map<String, Timer?> waveformTimers = {};
  Timer? _recordingTimer;
  int _recordedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _listenToCounsellorStatus();
    _initRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _audioPlayer!.openPlayer();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        FirebaseDatabase.instance.ref('userStates/${widget.userId}').update({
          'typing': false,
        });
      }
    });
  }

  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();

    if (await Permission.microphone.request().isDenied) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    audioPath =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _audioRecorder!.startRecorder(
      toFile: audioPath,
      codec: Codec.aacADTS,
    );
    _recordedSeconds = 0; // Reset
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordedSeconds++;
      });
    });

    setState(() => isRecording = true);
  }

  Future<void> _stopRecordingAndSend() async {
    await _audioRecorder!.stopRecorder();
    _recordingTimer?.cancel();
    setState(() => isRecording = false);

    if (audioPath != null) {
      File audioFile = File(audioPath!);
      print("Recorded seconds" + _recordedSeconds.toString());
      // ✅ duration in sec
      await _sendAudioFile(audioFile, _recordedSeconds);
    }
  }

  Future<void> _sendAudioFile(File audioFile, int durationInSeconds) async {
    String? receiverFCMToken;
    print("Duration in seconds " + durationInSeconds.toString());
    try {
      if (widget.role == 'user') {
        receiverFCMToken =
            await FirestoreService.getFCMTokenUser(widget.userId2);
      } else {
        receiverFCMToken =
            await FirestoreService.getFCMTokenCounsellor(widget.userId2);
      }

      if (receiverFCMToken != null && audioFile.existsSync()) {
        final audioBytes = await audioFile.readAsBytes();
        final tempId = 'temp-audio-${DateTime.now().millisecondsSinceEpoch}';

        Map<String, dynamic> tempMessage = {
          'id': tempId,
          'senderId': widget.userId,
          'fileName': 'Voice Note',
          'fileUrl': null,
          'fileType': 'audio/mpeg',
          'isSeen': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'duration': durationInSeconds,
          'localBytes': audioBytes,
          // 👈 Include duration
        };
        print("Temp Message");
        print(tempMessage);

        setState(() {
          messages.add(tempMessage);
          isUploading = true;
        });
        _scrollToBottom();

        try {
          await ChatService.sendFileMessage(
            chatId: chatId,
            senderId: widget.userId,
            file: audioFile,
            webFileBytes: null,
            fileName: 'voice_note.aac',
            receiverFcmToken: receiverFCMToken,
            // extraData: {'duration': durationInSeconds},
          );

          setState(() => isUploading = false);
          _loadMessages();
        } catch (e) {
          print("❌ Error sending audio: $e");
          setState(() {
            messages.removeWhere((msg) => msg['id'] == tempId);
            isUploading = false;
          });
        }
      }
    } catch (e) {
      print("❌ Error preparing to send audio: $e");
      setState(() => isUploading = false);
    }
  }

  Widget _buildAudioMessage(Map<String, dynamic> message) {
    final audioUrl = message['fileUrl'];
    final messageId = message['id'];
    final isThisPlaying = playingStates[messageId] ?? false;

    // Assuming duration is stored in seconds now
    final durationSec = message['duration']?.toString() ?? '0';
    print("Build Audio Message " + durationSec);
    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack, color: Colors.orange, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isThisPlaying
                    ? _waveformBars(messageId, true)
                    : Text("Voice Note",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                // Text(
                //   "$durationSec sec",
                //   style: TextStyle(fontSize: 12, color: Colors.grey),
                // ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isThisPlaying ? Icons.stop : Icons.play_arrow,
                color: Colors.black54),
            onPressed: () async {
              if (isThisPlaying) {
                await _audioPlayer!.stopPlayer();
                setState(() {
                  playingStates[messageId] = false;
                  _stopWaveformAnimation(messageId);
                });
              } else {
                await _audioPlayer!.stopPlayer();
                setState(() {
                  playingStates.updateAll((key, value) => false);
                });

                await _audioPlayer!.startPlayer(
                  fromURI: audioUrl,
                  codec: Codec.aacADTS,
                  whenFinished: () {
                    setState(() {
                      playingStates[messageId] = false;
                      _stopWaveformAnimation(messageId);
                    });
                  },
                );

                setState(() {
                  playingStates[messageId] = true;
                  _startWaveformAnimation(messageId);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _waveformBars(String messageId, bool isPlaying) {
    List<double> heights = waveformHeights[messageId] ??
        List<double>.filled(5, 8); // Default heights

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: heights.map((height) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  void _startWaveformAnimation(String messageId) {
    waveformTimers[messageId]?.cancel();

    waveformTimers[messageId] =
        Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() {
        waveformHeights[messageId] = List.generate(5, (_) {
          return 6 + (Random().nextDouble() * 14); // Heights between 6 and 20
        });
      });
    });
  }

  void _stopWaveformAnimation(String messageId) {
    waveformTimers[messageId]?.cancel();
    waveformTimers[messageId] = null;
    setState(() {
      waveformHeights[messageId] = List<double>.filled(5, 8); // Reset
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(1, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _captureImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      File imageFile = File(image.path);

      setState(() {
        selectedFile = imageFile;
        selectedFileName = p.basename(imageFile.path);
        webFileBytes = null;
        showSendButton = true;
      });

      await _sendFileMessage(); // Automatically send after capture
    }
  }

  Future<void> _captureVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);

    if (video != null) {
      File videoFile = File(video.path);

      setState(() {
        selectedFile = videoFile;
        selectedFileName = p.basename(videoFile.path);
        webFileBytes = null;
        showSendButton = true;
      });

      await _sendFileMessage(); // Automatically send after capture
    }
  }

  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.5), // Dimmed Background
      barrierColor:
          Colors.black.withOpacity(0.5), // Dims background outside sheet
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circleOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _captureImageFromCamera();
                  },
                ),
                _circleOption(
                  icon: Icons.videocam,
                  label: "Video",
                  onTap: () {
                    Navigator.pop(context);
                    _captureVideoFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper for Circular Buttons
  Widget _circleOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.withOpacity(0.8),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Future<void> _downloadImageWithDio(String imageUrl) async {
    final hasPermission = await _requestImagePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Permission denied")),
      );
      return;
    }

    try {
      final baseDir = Directory('/storage/emulated/0/Pictures/ProCounsellor');
      if (!(await baseDir.exists())) {
        await baseDir.create(recursive: true);
      }

      final fileName = "pro_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final fullPath = p.join(baseDir.path, fileName);

      final response = await Dio().download(imageUrl, fullPath);
      if (response.statusCode == 200) {
        print("✅ Image saved to $fullPath");

        final file = File(fullPath);

        // 1. Set modified date to now
        await file.setLastModified(DateTime.now());

        // 2. Re-create file (ensures Gallery re-indexes correctly)
        final tempPath = "$fullPath.tmp";
        await file.copy(tempPath);
        await file.delete();
        await File(tempPath).rename(fullPath);

        // 3. Scan for media
        await MediaScanner.loadMedia(path: fullPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Image saved to Gallery: $fullPath")),
        );
      } else {
        print("❌ Download failed: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save image")),
      );
    }
  }

  Future<bool> _requestImagePermission() async {
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdkVersion();
      if (sdk >= 33) {
        return await Permission.photos.request().isGranted;
      } else {
        return await Permission.storage.request().isGranted;
      }
    }
    return true;
  }

  Future<int> _getAndroidSdkVersion() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<void> _initializeChat() async {
    await _startChat();
    if (!isLoading) {
      _listenForNewMessages();
      _listenForSeenStatusUpdates();
      await _fetchUserProfile();
    }
  }

  Future<void> _startChat() async {
    try {
      // Replace this with the actual role (e.g., from widget or state)
      String role =
          widget.role; // Make sure widget.role exists or pass it otherwise

      String? result =
          await ChatService().startChat(widget.userId, widget.userId2, role);
      print("Role" + role);
      if (result != null) {
        chatId = result;
      } else {
        throw Exception('Chat ID is null');
      }

      // Fetch counsellor's profile data
      await _fetchUserProfile();

      setState(() {
        isLoading = false;
      });

      _loadMessages();
    } catch (e) {
      print('Error starting chat: $e');
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      String url;

      if (widget.role == 'user') {
        url = '${ApiUtils.baseUrl}/api/user/${widget.userId2}';
      } else {
        url = '${ApiUtils.baseUrl}/api/counsellor/${widget.userId2}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        setState(() {
          userPhotoUrl = widget.role == 'user'
              ? data['photo'] ?? userPhotoUrl
              : data['photoUrl'] ?? userPhotoUrl;
          userFirstName = data['firstName'] ?? '';
          userLastName = data['lastName'] ?? '';
        });
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void _listenToCounsellorStatus() {
    counsellorStateRef =
        FirebaseDatabase.instance.ref('userStates/${widget.userId2}');

    counsellorStateRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          isCounsellorOnline = data['state'] == 'online';
          isTyping = data['typing'] == true;
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? cachedData = prefs.getString('chat_cache_$chatId');
      if (cachedData != null) {
        List decoded = jsonDecode(cachedData);
        setState(() {
          messages = List<Map<String, dynamic>>.from(decoded);
        });
      }

      List<Map<String, dynamic>> fetchedMessages =
          await ChatService().getChatMessages(chatId);

      setState(() {
        // Clean any temp message if now replaced by real one
        messages.removeWhere(
            (msg) => msg['id']?.toString().startsWith('temp-') ?? false);

        messages = fetchedMessages;
      });

      print("Fetched Messages Durations:");
      fetchedMessages.forEach((msg) {
        print("ID: ${msg['id']} Duration: ${msg['duration']}");
      });

      prefs.setString('chat_cache_$chatId', jsonEncode(fetchedMessages));
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
              if (message['senderId'] == widget.userId2) {
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
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;

        if (kIsWeb) {
          webFileBytes = result.files.single.bytes;
          selectedFile = null;
        } else {
          selectedFile = File(result.files.single.path!);
          webFileBytes = result.files.single.bytes; // Preload here!
        }

        showSendButton = true;
      });
    }
  }

  Future<void> _sendMessage() async {
    String? receiverFCMToken;

    try {
      if (widget.role == 'user') {
        receiverFCMToken =
            await FirestoreService.getFCMTokenUser(widget.userId2);
      } else {
        receiverFCMToken =
            await FirestoreService.getFCMTokenCounsellor(widget.userId2);
      }

      print('Sending message to: ${widget.userId2}');
      print('Receiver FCM Token: $receiverFCMToken');

      if (_controller.text.isNotEmpty && receiverFCMToken != null) {
        MessageRequest messageRequest = MessageRequest(
          senderId: widget.userId,
          text: _controller.text,
          receiverFcmToken: receiverFCMToken,
        );

        print(messageRequest);

        await ChatService().sendMessage(chatId, messageRequest);

        _controller.clear();
        setState(() {
          showSendButton = selectedFile != null || webFileBytes != null;
        });
        _scrollToBottom();

        await FirebaseDatabase.instance
            .ref('userStates/${widget.userId}')
            .update({'typing': false});
      }
    } catch (e) {
      print(
          'Error sending message: $e (method: _sendMessage, user2userchatting)');
    }
  }

  Future<void> _sendFileMessage() async {
    String? receiverFCMToken;

    try {
      if (widget.role == 'user') {
        receiverFCMToken =
            await FirestoreService.getFCMTokenUser(widget.userId2);
      } else {
        receiverFCMToken =
            await FirestoreService.getFCMTokenCounsellor(widget.userId2);
      }

      if ((selectedFile != null || webFileBytes != null) &&
          receiverFCMToken != null) {
        // Save for later
        File? tempFile = selectedFile;
        Uint8List? tempWebBytes = webFileBytes;
        String tempFileName = selectedFileName!;

        Uint8List? localBytes = tempWebBytes ?? await tempFile!.readAsBytes();

        // Create the temp message IMMEDIATELY
        final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
        Map<String, dynamic> tempMessage = {
          'id': tempId,
          'senderId': widget.userId,
          'fileName': tempFileName,
          'fileUrl': null,
          'fileType': _isVideo(tempFileName) ? 'video/mp4' : 'image/jpeg',
          'isSeen': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'localBytes': localBytes,
        };

        setState(() {
          messages.add(tempMessage);
          isUploading = true;
          selectedFile = null;
          selectedFileName = null;
          webFileBytes = null;
          showSendButton = _controller.text.isNotEmpty;
        });
        _scrollToBottom();

        // THEN check size and upload
        int fileSizeBytes = localBytes.length;
        const maxSizeInBytes = 10 * 1024 * 1024;

        if (fileSizeBytes > maxSizeInBytes) {
          _showErrorDialog(
              "File too large", "This file exceeds the 10MB limit.");
          setState(() {
            messages.removeWhere((msg) => msg['id'] == tempId);
            isUploading = false;
          });
          return;
        }

        try {
          await ChatService.sendFileMessage(
            chatId: chatId,
            senderId: widget.userId,
            file: tempFile,
            webFileBytes: tempWebBytes,
            fileName: tempFileName,
            receiverFcmToken: receiverFCMToken,
          );

          setState(() => isUploading = false);
          _loadMessages();
        } catch (e) {
          print("❌ Error sending file: $e");
          setState(() {
            messages.removeWhere((msg) => msg['id'] == tempId);
            isUploading = false;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching FCM token: $e");
      setState(() => isUploading = false);
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
          '${ApiUtils.baseUrl}/api/chats/$chatId/messages/$messageId/mark-seen';
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
    _audioPlayer!.closePlayer();
    waveformTimers.forEach((_, timer) {
      timer?.cancel();
    });
    _audioPlayer = null;
    _focusNode.dispose(); // 👈 dispose it
    super.dispose();
  }

  Widget _buildImageMessage(Map<String, dynamic> message) {
    final imageUrl = message['fileUrl'];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Image Options"),
            content: Text("View or download this image?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFullImage(imageUrl); // existing viewer
                },
                child: Text("View"),
              ),
              // TextButton(
              //   onPressed: () async {
              //     Navigator.pop(context);
              //     final success = await GallerySaver.saveImage(
              //       imageUrl,
              //       albumName: 'ProCounsellor',
              //     );
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Text(success == true
              //             ? "✅ Image saved to Gallery"
              //             : "❌ Failed to save image"),
              //       ),
              //     );
              //   },
              //   child: Text("Download"),
              // ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await _downloadAndSaveAsPng(imageUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? "✅ Image saved to Gallery"
                          : "❌ Failed to save image"),
                    ),
                  );
                },
                child: Text("Download"),
              ),
            ],
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdk = await DeviceInfoPlugin()
          .androidInfo
          .then((info) => info.version.sdkInt);

      if (sdk >= 30) {
        // Android 11+
        return await Permission.manageExternalStorage.request().isGranted;
      } else if (sdk >= 23) {
        // Android 6-10
        return await Permission.storage.request().isGranted;
      } else {
        // Older versions don't need runtime permission
        return true;
      }
    }
    return true; // iOS/Web don't need this
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          child: Image.network(url),
        ),
      ),
    );
  }

  Future<bool> _downloadAndSaveAsPng(String imageUrl) async {
    try {
      if (!(await _requestStoragePermission())) {
        print("❌ Permission denied");
        return false;
      }

      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final originalBytes = Uint8List.fromList(response.data!);
      final decodedImage = img.decodeImage(originalBytes);
      if (decodedImage == null) {
        print("❌ Could not decode image");
        return false;
      }

      final pngBytes = img.encodePng(decodedImage);

      // ✅ Platform-specific handling
      if (Platform.isAndroid) {
        final baseDir = Directory('/storage/emulated/0/Pictures/ProCounsellor');
        if (!(await baseDir.exists())) {
          await baseDir.create(recursive: true);
        }

        final fileName =
            "pro_image_${DateTime.now().millisecondsSinceEpoch}.png";
        final fullPath = '${baseDir.path}/$fileName';

        final file = await File(fullPath).writeAsBytes(pngBytes);
        await file.setLastModified(DateTime.now());
        await MediaScanner.loadMedia(path: file.path);

        print("✅ PNG saved on Android: $fullPath");
        return true;
      } else if (Platform.isIOS) {
        // Save PNG bytes to temp file
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final tempFile = await File(tempPath).writeAsBytes(pngBytes);

        // Use GallerySaver on iOS
        final success = await GallerySaver.saveImage(tempFile.path,
            albumName: 'ProCounsellor');
        print(success == true ? "✅ PNG saved on iOS" : "❌ Failed on iOS");
        return success ?? false;
      } else {
        print("❌ Unsupported Platform");
        return false;
      }
    } catch (e) {
      print("❌ Error saving PNG: $e");
      return false;
    }
  }

  // Future<bool> _downloadAndSaveImageWithNewDate(String imageUrl) async {
  //   try {
  //     // Request permissions based on Android version
  //     if (!(await _requestImagePermission())) {
  //       print("❌ Permission denied");
  //       return false;
  //     }

  //     // Download image as bytes
  //     final response = await Dio().get<List<int>>(
  //       imageUrl,
  //       options: Options(responseType: ResponseType.bytes),
  //     );

  //     final originalBytes = Uint8List.fromList(response.data!);
  //     final decodedImage = img.decodeImage(originalBytes);
  //     if (decodedImage == null) {
  //       print("❌ Could not decode image");
  //       return false;
  //     }

  //     // Re-encode image without metadata
  //     final strippedBytes = img.encodeJpg(decodedImage);

  //     // Save re-encoded image to temp
  //     final tempDir = await getTemporaryDirectory();
  //     final tempPath =
  //         '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     final tempFile = await File(tempPath).writeAsBytes(strippedBytes);

  //     // Save to gallery
  //     final gallerySaved = await GallerySaver.saveImage(tempFile.path,
  //         albumName: 'ProCounsellor');

  //     if (gallerySaved == true) {
  //       print("✅ Image saved with new date: $tempPath");
  //     } else {
  //       print("❌ GallerySaver failed");
  //     }

  //     // Optionally delete temp file
  //     if (await tempFile.exists()) {
  //       await tempFile.delete();
  //     }

  //     return gallerySaved ?? false;
  //   } catch (e) {
  //     print("❌ Error saving image with new date: $e");
  //     return false;
  //   }
  // }

  // Future<bool> _downloadAndSaveImageWithoutMetadata(String imageUrl) async {
  //   try {
  //     final tempDir = await getTemporaryDirectory();
  //     final tempPath =
  //         '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

  //     // 1. Download image
  //     final response = await Dio().get<List<int>>(
  //       imageUrl,
  //       options: Options(responseType: ResponseType.bytes),
  //     );

  //     // 2. Decode image to strip metadata
  //     final originalBytes = Uint8List.fromList(response.data!);
  //     final decodedImage = img.decodeImage(originalBytes);
  //     if (decodedImage == null) throw Exception("Image decode failed");

  //     // 3. Encode without metadata
  //     final strippedBytes = img.encodeJpg(decodedImage);

  //     // 4. Save to temp file
  //     final tempFile = await File(tempPath).writeAsBytes(strippedBytes);

  //     // 5. Move to gallery
  //     final galleryResult = await GallerySaver.saveImage(tempFile.path,
  //         albumName: 'ProCounsellor');
  //     print("✅ Image saved with new date: $galleryResult");

  //     return galleryResult ?? false;
  //   } catch (e) {
  //     print("❌ Error saving image without metadata: $e");
  //     return false;
  //   }
  // }

  Future<void> _downloadVideoWithDio(String videoUrl) async {
    final hasPermission = await _requestImagePermission(); // same logic works
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Permission denied")),
      );
      return;
    }

    try {
      final baseDir = Directory('/storage/emulated/0/Movies/ProCounsellor');
      if (!(await baseDir.exists())) {
        await baseDir.create(recursive: true);
      }

      final fileName = "pro_video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final fullPath = p.join(baseDir.path, fileName);

      final response = await Dio().download(
        videoUrl,
        fullPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "🎬 Downloading video: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        print("✅ Video saved to $fullPath");

        // 👇 Trigger gallery scan
        await MediaScanner.loadMedia(path: fullPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Video now visible in Gallery")),
        );
      } else {
        print("❌ Video download failed: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ Error downloading video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to download video")),
      );
    }
  }

  // Widget _buildVideoMessage(Map<String, dynamic> message) {
  //   if (kIsWeb) {
  //     // On Web, open video in a new browser tab
  //     return GestureDetector(
  //       onTap: () {
  //         _launchURL(message['fileUrl']);
  //       },
  //       child: Container(
  //         width: 200,
  //         height: 120,
  //         decoration: BoxDecoration(
  //           color: Colors.black,
  //           borderRadius: BorderRadius.circular(8.0),
  //         ),
  //         child: Stack(
  //           alignment: Alignment.center,
  //           children: [
  //             Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
  //           ],
  //         ),
  //       ),
  //     );
  //   } else {
  //     // Mobile/Desktop: Show video preview and play inside the app
  //     return GestureDetector(
  //       onTap: () {
  //         showDialog(
  //           context: context,
  //           builder: (_) => Dialog(
  //             backgroundColor: Colors.black,
  //             child: VideoPlayerWidget(videoUrl: message['fileUrl']),
  //           ),
  //         );
  //       },
  //       child: Container(
  //         width: 200,
  //         height: 120,
  //         decoration: BoxDecoration(
  //           color: Colors.black,
  //           borderRadius: BorderRadius.circular(8.0),
  //         ),
  //         child: Stack(
  //           alignment: Alignment.center,
  //           children: [
  //             Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }

  Widget _buildVideoMessage(Map<String, dynamic> message) {
    final videoUrl = message['fileUrl'];

    if (kIsWeb) {
      return GestureDetector(
        onTap: () => _launchURL(videoUrl),
        child: _videoThumbnail(),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Video Options"),
            content: Text("Play or download this video?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      child: VideoPlayerWidget(videoUrl: videoUrl),
                    ),
                  );
                },
                child: Text("Play"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await GallerySaver.saveVideo(
                    videoUrl,
                    albumName: 'ProCounsellor',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success == true
                          ? "✅ Video saved to Gallery"
                          : "❌ Failed to save video"),
                    ),
                  );
                },
                child: Text("Download"),
              ),
            ],
          ),
        );
      },
      child: _videoThumbnail(),
    );
  }

// 🔽 This is just your video box design extracted as a helper
  Widget _videoThumbnail() {
    return Container(
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
    );
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

  // void _downloadFile(String url) async {
  //   Uri uri = Uri.parse(url); // Convert string to Uri
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     print("Could not launch $url");
  //   }
  // }

  void _downloadFile(String fileUrl) async {
    final hasPermission =
        await _requestImagePermission(); // reuse permission logic
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Permission denied")),
      );
      return;
    }

    try {
      final baseDir = Directory('/storage/emulated/0/Download/ProCounsellor');
      if (!(await baseDir.exists())) {
        await baseDir.create(recursive: true);
      }

      final fileName =
          "pro_file_${DateTime.now().millisecondsSinceEpoch}_${p.basename(fileUrl)}";
      final fullPath = p.join(baseDir.path, fileName);

      final response = await Dio().download(
        fileUrl,
        fullPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "📥 Downloading file: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        print("✅ File saved to $fullPath");
        await MediaScanner.loadMedia(path: fullPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ File saved to Downloads: $fullPath")),
        );
      } else {
        print("❌ File download failed: ${response.statusMessage}");
      }
    } catch (e) {
      print("❌ Error downloading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to download file")),
      );
    }
  }

  Widget _buildMessageWidget(Map<String, dynamic> message) {
    //print("🔍 BUILDING MESSAGE WIDGET: $message");

    if (message['fileUrl'] != null || message['fileType'] != null) {
      String fileType = message['fileType'] ?? 'unknown';

      // Handle uploading temp message (no URL but localBytes exists)
      if (message['fileUrl'] == null && message['localBytes'] != null) {
        return _buildUploadingFileMessage(message);
      }

      if (fileType.startsWith('image/')) {
        return _buildImageMessage(message);
      } else if (fileType.startsWith('video/')) {
        return _buildVideoMessage(message);
      } else if (fileType.startsWith('audio/')) {
        return _buildAudioMessage(message);
      } else {
        return _buildFileMessage(message);
      }
    }

    // If it's plain text
    return Text(
      message['text'] ?? 'No message',
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
    );
  }

// Dimmed overlay helper
  Widget _dimmedOverlayWithLoader() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // Widget _buildUploadingFileMessage(Map<String, dynamic> message) {
  //   return Container(
  //     padding: EdgeInsets.all(10),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(Icons.upload, color: Colors.blue),
  //         SizedBox(width: 8),
  //         Expanded(
  //           child: Text(
  //             message['fileName'] ?? "Uploading...",
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ),
  //         CircularProgressIndicator(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildUploadingFileMessage(Map<String, dynamic> message) {
    final localBytes = message['localBytes'];
    final fileType = message['fileType'] ?? 'unknown';

    print("📝 FILE TYPE CHECK: $fileType");

    Widget preview;

    // Strictly validate image types
    if (fileType.startsWith('image/')) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          localBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.4),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (context, error, stackTrace) {
            print("❌ Image error: $error");
            return Container(
              color: Colors.grey,
              child: Icon(Icons.document_scanner, color: Colors.grey, size: 40),
            );
          },
        ),
      );
    } else if (fileType.startsWith('video/')) {
      preview = Container(
        color: Colors.black,
        child: Icon(Icons.play_circle_fill,
            color: Colors.white.withOpacity(0.7), size: 50),
      );
    } else {
      preview = Container(
        color: Colors.grey[300],
        child: Icon(Icons.insert_drive_file, color: Colors.black54, size: 50),
      );
    }

    return Container(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          preview,
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailsPage(
                  userId: widget.userId2,
                  myUsername: widget.userId,
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
                    backgroundImage: NetworkImage(userPhotoUrl),
                    radius: 22,
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
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$userFirstName $userLastName",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isTyping
                        ? "Typing..."
                        : (isCounsellorOnline ? "Online" : "Offline"),
                    style: TextStyle(
                      color: isTyping
                          ? Colors.purple
                          : (isCounsellorOnline ? Colors.green : Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                              child: _buildMessageWidget(message),
                            ),
                          ),

                          // Show 'Seen' text for last message
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
                if (selectedFileName != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Media Preview OR File Icon
                            if (webFileBytes != null &&
                                !_isVideo(selectedFileName!) &&
                                !_isDocument(selectedFileName!))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  child: Image.memory(webFileBytes!,
                                      fit: BoxFit.cover),
                                ),
                              )
                            else if (_isVideo(selectedFileName!))
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 36),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.insert_drive_file,
                                    color: Colors.blueGrey, size: 30),
                              ),

                            // 🔄 Loading Spinner Overlay
                            if (isUploading) // <-- Add this state
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 12),
                        // File Name + Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedFileName!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 6),
                              Text(
                                isUploading ? "Uploading..." : "Ready to send",
                                style: TextStyle(
                                    color: isUploading
                                        ? Colors.orange
                                        : Colors.green,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red, size: 22),
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                              selectedFileName = null;
                              webFileBytes = null;
                              isUploading = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                if (isTyping && !isLoading) _buildTypingIndicator(),
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
                          onPressed: () {
                            _showCameraOptions(context);
                          },
                        ),
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: showSendButton
                              ? MediaQuery.of(context).size.width * 0.8
                              : MediaQuery.of(context).size.width * 0.65,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: (text) {
                              setState(() {
                                showSendButton = text.isNotEmpty ||
                                    selectedFile != null ||
                                    webFileBytes != null;
                              });

                              FirebaseDatabase.instance
                                  .ref('userStates/${widget.userId}')
                                  .update({
                                'typing': text.isNotEmpty,
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
                      showSendButton
                          ? IconButton(
                              icon: Icon(Icons.send, color: Colors.black54),
                              onPressed: () {
                                if (_controller.text.isNotEmpty) _sendMessage();
                                if (selectedFile != null ||
                                    webFileBytes != null) _sendFileMessage();
                              },
                            )
                          : GestureDetector(
                              onLongPressStart: (_) async {
                                HapticFeedback.lightImpact();
                                await _startRecording();
                                setState(() => isRecording = true);
                              },
                              onLongPressEnd: (_) async {
                                await _stopRecordingAndSend();
                                setState(() => isRecording = false);
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isRecording)
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                      child: Icon(Icons.mic,
                                          color: Colors.red, size: 30),
                                    )
                                  else
                                    Icon(Icons.mic,
                                        color: Colors.black54, size: 30),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
    );
  }

  bool _isImage(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  bool _isVideo(String fileName) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv'];
    return videoExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  bool _isDocument(String fileName) {
    final docExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt'
    ];
    return docExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 5.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(userPhotoUrl),
          ),
          const SizedBox(width: 8),
          const SpinKitThreeBounce(
            color: Colors.grey,
            size: 18.0,
          ),
        ],
      ),
    );
  }
}
