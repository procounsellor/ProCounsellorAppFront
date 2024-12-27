import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class MessageRequest {
  final String senderId;
  final String text;

  MessageRequest({required this.senderId, required this.text});

  // Convert the MessageRequest object to JSON format for the request body
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'isSeen': false, // Default value for new messages
    };
  }
}

class ChatService {
  static const String baseUrl = 'http://localhost:8080/api/chats';
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
  Future<String?> startChat(String userId, String counsellorId) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/start-chat?userId=$userId&counsellorId=$counsellorId'),
    );

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

  // Get chat messages
  Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    print(chatId);
    final response = await http.get(
      Uri.parse('$baseUrl/$chatId/messages'),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);

      // Parse response without timestamp
      return (responseBody as List<dynamic>).map((msg) {
        return {
          'id': msg['id'] ?? '',
          'senderId': msg['senderId'] ?? 'Unknown',
          'text': msg['text'] ?? 'No message',
          'isSeen': msg['isSeen'] ?? false, // Add the 'isSeen' field here
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }

  // Listen for real-time updates to messages
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
        newMessages.add({
          'id': event.snapshot.key ?? '',
          'senderId': messageData['senderId'] ?? 'Unknown',
          'text': messageData['text'] ?? 'No message',
          'isSeen':
              messageData['isSeen'] ?? false, // Ensure 'isSeen' is included
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
        updatedMessages.add({
          'id': event.snapshot.key ?? '',
          'senderId': messageData['senderId'] ?? 'Unknown',
          'text': messageData['text'] ?? 'No message',
          'isSeen':
              messageData['isSeen'] ?? false, // Ensure 'isSeen' is included
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
