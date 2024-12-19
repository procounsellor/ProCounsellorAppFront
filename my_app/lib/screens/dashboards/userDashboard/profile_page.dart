import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For decoding the JSON response

class ProfilePage extends StatefulWidget {
  final String username;

  ProfilePage({required this.username});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> subscribedCounsellors = [];
  bool isLoading = true; // To show a loading indicator while fetching data

  @override
  void initState() {
    super.initState();
  }

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
            // Profile Picture and User Info
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text("Username: ${widget.username}",
                style: TextStyle(fontSize: 18)),
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
