import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../../services/api_utils.dart';

class MessageRequest {
  final String senderId;
  final String text;
  final String receiverFcmToken;

  MessageRequest(
      {required this.senderId,
      required this.text,
      required this.receiverFcmToken});

  // Convert the MessageRequest object to JSON format for the request body
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'receiverFcmToken': receiverFcmToken,
      'isSeen': false, // Default value for new messages
    };
  }
}

class ChatService {
  static const String baseUrl = '${ApiUtils.baseUrl}/api/chats';
  final Map<String, StreamSubscription> _activeListeners = {};

  // Mark a message as seen
  Future<void> markMessageAsSeen(
      String chatId, String messageId, String viewerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$chatId/messages/$messageId/mark-seen'),
        body: jsonEncode({'viewerId': viewerId}), // Include viewerId
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as seen: ${response.body}');
      }

      // Update the 'isSeen' field in the Firebase Realtime Database
      FirebaseDatabase database = FirebaseDatabase.instance;
      DatabaseReference messageRef =
          database.ref('chats/$chatId/messages/$messageId');
      await messageRef
          .update({'isSeen': true}); // Mark message as seen in the database
    } catch (e) {
      print('Error marking message as seen: $e');
    }
  }

  // Start a new chat
  Future<String?> startChat(String userId, String userId2, String role) async {
    http.Response response;
    print("role" + role + " user" + userId2);
    if (role == "user") {
      response = await http.post(
        Uri.parse(
            '$baseUrl/start-chat-userTouser?userId=$userId&userId2=$userId2'),
      );
    } else {
      response = await http.post(
        Uri.parse('$baseUrl/start-chat?userId=$userId&counsellorId=$userId2'),
      );
    }
    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      return responseBody['chatId'];
    } else {
      throw Exception('Failed to start chat: ${response.body}');
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, MessageRequest messageRequest) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$chatId/messages'),
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode(messageRequest.toJson()), // Send the entire message object
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // static Future<void> sendFileMessage({
  //   required String chatId,
  //   required String senderId,
  //   required File? file,
  //   required Uint8List? webFileBytes,
  //   required String fileName,
  //   required String receiverFcmToken,
  // }) async {
  //   try {
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/files'),
  //     );

  //     request.fields['senderId'] = senderId;
  //     request.fields['receiverFcmToken'] = receiverFcmToken;

  //     // Determine file MIME type
  //     String? mimeType;

  //     if (kIsWeb && webFileBytes != null) {
  //       mimeType = lookupMimeType(fileName); // Detect MIME type for Web
  //       request.files.add(http.MultipartFile.fromBytes(
  //         'file',
  //         webFileBytes,
  //         filename: fileName,
  //         contentType: mimeType != null ? MediaType.parse(mimeType) : null,
  //       ));
  //     } else if (file != null) {
  //       mimeType =
  //           lookupMimeType(file.path); // Detect MIME type for Mobile/Desktop
  //       request.files.add(await http.MultipartFile.fromPath(
  //         'file',
  //         file.path,
  //         contentType: mimeType != null ? MediaType.parse(mimeType) : null,
  //       ));
  //     }

  //     var response = await request.send();
  //     if (response.statusCode == 201) {
  //       print("✅ File sent successfully!");
  //     } else {
  //       print("❌ Failed to send file: ${response.reasonPhrase}");
  //     }
  //   } catch (e) {
  //     print("❌ Error sending file: $e");
  //   }
  // }

  static Future<String> sendFileMessage({
    required String chatId,
    required String senderId,
    required File? file,
    required Uint8List? webFileBytes,
    required String fileName,
    required String receiverFcmToken,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/files'),
      );

      request.fields['senderId'] = senderId;
      request.fields['receiverFcmToken'] = receiverFcmToken;

      // Determine file MIME type
      String? mimeType;

      if (kIsWeb && webFileBytes != null) {
        mimeType = lookupMimeType(fileName);
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webFileBytes,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      } else if (file != null) {
        mimeType = lookupMimeType(file.path);
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ File sent successfully!");
        final body = response.body;
        print("🔵 Backend Response: $body");

        // Extract URL from backend response
        final regex = RegExp(r'URL:\s*(https?://\S+)', caseSensitive: false);
        final match = regex.firstMatch(body);

        if (match != null) {
          final fileUrl = match.group(1);
          print("🔗 Extracted URL: $fileUrl");
          return fileUrl!;
        } else {
          throw Exception("URL not found in response: $body");
        }
      } else {
        print("❌ Failed to send file: ${response.reasonPhrase}");
        throw Exception("File upload failed");
      }
    } catch (e) {
      print("❌ Error sending file: $e");
      rethrow;
    }
  }

  // Get chat messages
  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$chatId/messages'),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);

      return (responseBody as List<dynamic>).map((msg) {
        return {
          'id': msg['id'] ?? '',
          'senderId': msg['senderId'] ?? 'Unknown',
          'text': msg.containsKey('text')
              ? msg['text']
              : null, // Handle text messages
          'fileUrl': msg.containsKey('fileUrl')
              ? msg['fileUrl']
              : null, // Handle media
          'fileName': msg.containsKey('fileName') ? msg['fileName'] : null,
          'fileType': msg.containsKey('fileType') ? msg['fileType'] : null,
          'isSeen': msg['isSeen'] ?? false,
          'timestamp': msg['timestamp'] ?? 0,
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }

  // Listen for real-time updates to messages, including files
  void listenForNewMessages(
      String chatId, Function(List<Map<String, dynamic>>) onNewMessages) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference messagesRef = database.ref('chats/$chatId/messages');

    // Start listening to new messages
    StreamSubscription subscription = messagesRef.onChildAdded.listen((event) {
      List<Map<String, dynamic>> newMessages = [];

      if (event.snapshot.value is Map) {
        var messageData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        // Check if it's a text or file message
        newMessages.add({
          'id': event.snapshot.key ?? '',
          'senderId': messageData['senderId'] ?? 'Unknown',
          'text': messageData.containsKey('text') ? messageData['text'] : null,
          'fileUrl': messageData.containsKey('fileUrl')
              ? messageData['fileUrl']
              : null,
          'fileName': messageData.containsKey('fileName')
              ? messageData['fileName']
              : null,
          'fileType': messageData.containsKey('fileType')
              ? messageData['fileType']
              : null,
          'isSeen':
              messageData['isSeen'] ?? false, // Ensure 'isSeen' is included
          'timestamp': messageData['timestamp'] ?? 0, // Ensure correct ordering
        });
      }

      onNewMessages(newMessages);
    });

    // Listen for updates to existing messages
    messagesRef.onChildChanged.listen((event) {
      List<Map<String, dynamic>> updatedMessages = [];

      if (event.snapshot.value is Map) {
        var messageData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        // Check if it's a text or file message
        updatedMessages.add({
          'id': event.snapshot.key ?? '',
          'senderId': messageData['senderId'] ?? 'Unknown',
          'text': messageData.containsKey('text') ? messageData['text'] : null,
          'fileUrl': messageData.containsKey('fileUrl')
              ? messageData['fileUrl']
              : null,
          'fileName': messageData.containsKey('fileName')
              ? messageData['fileName']
              : null,
          'fileType': messageData.containsKey('fileType')
              ? messageData['fileType']
              : null,
          'isSeen':
              messageData['isSeen'] ?? false, // Ensure 'isSeen' is included
          'timestamp': messageData['timestamp'] ?? 0, // Ensure correct ordering
        });
      }

      onNewMessages(updatedMessages); // Notify the listener of updates
    });

    // Save the subscription for later cleanup
    _activeListeners[chatId] = subscription;
  }

  // Listen for updates to the 'isSeen' field in real-time
  void listenForSeenStatusUpdates(
      String chatId, Function(List<Map<String, dynamic>>) onSeenStatusUpdates) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference messagesRef = database.ref('chats/$chatId/messages');

    // Listen for changes to the 'isSeen' field of existing messages
    StreamSubscription subscription =
        messagesRef.onChildChanged.listen((event) {
      List<Map<String, dynamic>> updatedMessages = [];

      if (event.snapshot.value is Map) {
        var messageData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        if (messageData.containsKey('isSeen')) {
          updatedMessages.add({
            'id': event.snapshot.key ?? '',
            'senderId': messageData['senderId'] ?? 'Unknown',
            'text': messageData['text'] ?? 'No message',
            'isSeen':
                messageData['isSeen'] ?? false, // Ensure 'isSeen' is included
          });
        }
      }

      if (updatedMessages.isNotEmpty) {
        onSeenStatusUpdates(updatedMessages);
      }
    });

    // Save the subscription for later cleanup
    _activeListeners[chatId] = subscription;
  }

  // Cancel listeners for a specific chat
  void cancelListeners(String chatId) {
    if (_activeListeners.containsKey(chatId)) {
      _activeListeners[chatId]?.cancel();
      _activeListeners.remove(chatId);
    }
  }

  // Cancel all active listeners (optional utility)
  void cancelAllListeners() {
    _activeListeners.values.forEach((subscription) => subscription.cancel());
    _activeListeners.clear();
  }
}
