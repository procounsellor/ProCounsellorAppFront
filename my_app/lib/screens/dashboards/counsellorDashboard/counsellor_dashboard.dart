import 'package:flutter/material.dart';

class CounsellorDashboard extends StatelessWidget {
  final VoidCallback onSignOut;

  CounsellorDashboard(
      {required this.onSignOut}); // Define the onSignOut parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                onSignOut, // Call the onSignOut method when logout is pressed
          ),
        ],
      ),
      body: Center(child: Text("Welcome to the Councellor Dashboard")),
    );
  }
}
