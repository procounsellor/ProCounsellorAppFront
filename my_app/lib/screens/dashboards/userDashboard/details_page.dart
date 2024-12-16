import 'package:flutter/material.dart';
import 'chatting_page.dart'; // Import the ChattingPage

class DetailsPage extends StatelessWidget {
  final String itemName;
  final String userId;
  final String counsellorId; // Add counsellorId

  DetailsPage(
      {required this.itemName,
      required this.userId,
      required this.counsellorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Details about $itemName",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Call functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Calling $itemName...")),
                );
              },
              icon: Icon(Icons.call),
              label: Text("Call"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Chat functionality here, pass the counsellorId to ChattingPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChattingPage(
                      itemName: itemName,
                      userId: userId,
                      counsellorId: counsellorId, // Pass the counsellorId
                    ),
                  ),
                );
              },
              icon: Icon(Icons.chat),
              label: Text("Chat"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Video call functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Video calling $itemName...")),
                );
              },
              icon: Icon(Icons.video_call),
              label: Text("Video Call"),
            ),
          ],
        ),
      ),
    );
  }
}
