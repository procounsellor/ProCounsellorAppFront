import 'package:flutter/material.dart';
import 'counsellor_chatting_page.dart';

class ClientDetailsPage extends StatelessWidget {
  final Map<String, dynamic> client;
  final String counsellorId;

  ClientDetailsPage({required this.client, required this.counsellorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${client['firstName']} ${client['lastName']}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                client['photo'] ?? 'https://via.placeholder.com/150',
              ),
            ),
            SizedBox(height: 20),
            Text("Name: ${client['firstName']} ${client['lastName']}"),
            Text("Email: ${client['email']}"),
            Text("Phone: ${client['phoneNumber'] ?? 'N/A'}"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.chat),
              label: Text("Chat"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChattingPage(
                      itemName: "${client['firstName']} ${client['lastName']}",
                      userId:
                          client['userName'], // Assuming 'id' is the user's ID
                      counsellorId: counsellorId,
                      photo: client['photo'],
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.call),
              label: Text("Call"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Calling ${client['firstName']}...")),
                );
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.videocam),
              label: Text("Video Call"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "Starting video call with ${client['firstName']}...")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
