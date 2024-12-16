import 'package:flutter/material.dart';

class LikedVideosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liked Videos"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: 10, // Example: Replace with actual video data count
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.video_library, color: Color(0xFFF0BB78)),
              title: Text("Video ${index + 1}"),
              subtitle: Text("This is a liked video."),
              trailing: Icon(Icons.play_arrow, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Playing Video ${index + 1}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
