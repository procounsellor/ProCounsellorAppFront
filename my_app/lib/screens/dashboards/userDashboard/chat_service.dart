import 'dart:convert';
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
  static const String baseUrl =
      'http://localhost:8080/api/chats'; // Replace with your backend URL

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
    print(messageRequest.senderId + " : " + messageRequest.text);
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

      // Ensure the response is parsed as a list of maps
      return (responseBody as List<dynamic>).map((msg) {
        // Safely handle each field
        return {
          'id': msg['id'] ?? '',
          'senderId': msg['senderId'] ?? 'Unknown',
          'text': msg['text'] ?? 'No message',
          'timestamp': msg['timestamp'] != null
              ? {
                  'seconds': msg['timestamp']['seconds'] ?? 0,
                  'nanos': msg['timestamp']['nanos'] ?? 0,
                }
              : {'seconds': 0, 'nanos': 0},
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }
}
