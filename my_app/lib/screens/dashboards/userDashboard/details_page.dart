import 'package:flutter/material.dart';
import 'chatting_page.dart';

class DetailsPage extends StatelessWidget {
  final String itemName;
  final String userId;
  final String counsellorId; // Add counsellorId

  // Modify constructor to accept userId
  DetailsPage({
    required this.itemName,
    required this.userId, // Accept userId here
    required this.counsellorId,
  });

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
            // Title displaying the item name
            Text(
              "Details about $itemName",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Call Button
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
            SizedBox(height: 10),

            // Chat Button
            ElevatedButton.icon(
              onPressed: () {
                // Chat functionality here, pass the counsellorId to ChattingPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChattingPage(
                      itemName: itemName,
                      userId: userId, // Pass the userId to the ChattingPage
                      counsellorId: counsellorId, // Pass the counsellorId
                    ),
                  ),
                );
              },
              icon: Icon(Icons.chat),
              label: Text("Chat"),
            ),
            SizedBox(height: 10),

            // Video Call Button
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
            SizedBox(height: 20),

            // Optional: TextField to add notes or additional information
            TextField(
              decoration: InputDecoration(
                labelText: 'Add a note...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
