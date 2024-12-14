import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String itemName;

  DetailsPage({required this.itemName});

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
                // Chat functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Chatting with $itemName...")),
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
