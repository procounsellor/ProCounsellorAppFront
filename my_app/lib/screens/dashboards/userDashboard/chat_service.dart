import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageRequest {
  final String senderId;
  final String text;

  MessageRequest({required this.senderId, required this.text});

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
    };
  }
}

class ChatService {
  static const String baseUrl = 'http://localhost:8080/api/chats';

  Future<String> startChat(String userId, String counsellorId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/start-chat?userId=$userId&counsellorId=$counsellorId'),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      return responseBody['chatId'];
    } else {
      throw Exception('Failed to start chat: ${response.body}');
    }
  }

  Future<void> sendMessage(String chatId, MessageRequest messageRequest) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$chatId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageRequest.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

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
          'text': msg['text'] ?? 'No message',
          'timestamp': msg['timestamp'] ?? {},
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }
}
