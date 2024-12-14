import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final VoidCallback onSignOut;

  AdminDashboard({required this.onSignOut}); // Define the onSignOut parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                onSignOut, // Call the onSignOut method when logout is pressed
          ),
        ],
      ),
      body: Center(child: Text("Welcome to the Admin Dashboard")),
    );
  }
}
