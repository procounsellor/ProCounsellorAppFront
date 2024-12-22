import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chatting_page.dart'; // Import the ChattingPage

class ChatPage extends StatefulWidget {
  final String userId;

  ChatPage({required this.userId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> counsellorsWithChats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubscribedCounsellorsWithChats();
  }

  Future<void> fetchSubscribedCounsellorsWithChats() async {
    try {
      // Fetch subscribed counsellors
      final subscribedUrl = Uri.parse(
          'http://localhost:8080/api/user/${widget.userId}/subscribed-counsellors');
      final subscribedResponse = await http.get(subscribedUrl);

      if (subscribedResponse.statusCode == 200) {
        final subscribedCounsellors =
            json.decode(subscribedResponse.body) as List<dynamic>;

        // Filter counsellors with existing chats
        List<Map<String, dynamic>> filteredCounsellors = [];
        for (var counsellor in subscribedCounsellors) {
          final counsellorId = counsellor['userName'];
          final counsellorName =
              counsellor['firstName'] ?? 'Unknown Counsellor';
          final counsellorPhotoUrl =
              counsellor['photoUrl'] ?? 'https://via.placeholder.com/150';

          final chatExistsUrl = Uri.parse(
              'http://localhost:8080/api/chats/exists?userId=${widget.userId}&counsellorId=$counsellorId');
          final chatExistsResponse = await http.get(chatExistsUrl);

          if (chatExistsResponse.statusCode == 200) {
            final chatExists = json.decode(chatExistsResponse.body) as bool;
            if (chatExists) {
              filteredCounsellors.add({
                'id': counsellorId,
                'name': counsellorName,
                'photoUrl': counsellorPhotoUrl,
              });
            }
          }
        }

        setState(() {
          counsellorsWithChats = filteredCounsellors;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch subscribed counsellors");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Chats"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : counsellorsWithChats.isEmpty
              ? Center(child: Text("No chats available"))
              : ListView.builder(
                  itemCount: counsellorsWithChats.length,
                  itemBuilder: (context, index) {
                    final counsellor = counsellorsWithChats[index];
                    final name = counsellor['name'] ?? 'Unknown Counsellor';
                    final photoUrl = counsellor['photoUrl'] ??
                        'https://via.placeholder.com/150';
                    final counsellorId = counsellor['id'];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(photoUrl),
                        ),
                        title: Text(name),
                        trailing: IconButton(
                          icon: Icon(Icons.chat),
                          onPressed: () {
                            // Navigate to ChattingPage with necessary parameters
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChattingPage(
                                  itemName: name,
                                  userId: widget.userId,
                                  counsellorId: counsellorId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
