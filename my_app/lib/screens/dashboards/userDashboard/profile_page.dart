import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String username;

  ProfilePage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text("Username: $username", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Email: user@example.com", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Membership: Premium", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Edit Profile Coming Soon!")),
                );
              },
              child: Text("Edit Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
