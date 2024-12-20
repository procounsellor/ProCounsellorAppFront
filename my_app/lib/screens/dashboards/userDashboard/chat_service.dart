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
    };
  }
}

class ChatService {
  static const String baseUrl = 'http://localhost:8080/api/chats';
  final Map<String, StreamSubscription> _activeListeners = {};

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
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
}

// Listen for real-time updates to messages
  void listenForNewMessages(String chatId, Function(List<Map<String, dynamic>>) onNewMessages) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference messagesRef = database.ref('chats/$chatId/messages');

    // Start listening to new messages
    StreamSubscription subscription = messagesRef.onChildAdded.listen((event) {
      List<Map<String, dynamic>> newMessages = [];

      if (event.snapshot.value is Map) {
        var messageData = Map<String, dynamic>.from(event.snapshot.value as Map);
        newMessages.add({
          'id': event.snapshot.key ?? '',
          'senderId': messageData['senderId'] ?? 'Unknown',
          'text': messageData['text'] ?? 'No message',
        });
      }

      onNewMessages(newMessages);
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

