import 'package:flutter/material.dart';

// In your `UserDashboard` (and similar dashboards)
class UserDashboard extends StatelessWidget {
  final VoidCallback onSignOut;

  UserDashboard({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome to the User Dashboard"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSignOut, // Trigger sign-out here
              child: Text("Sign Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red color for Sign Out button
              ),
            ),
          ],
        ),
      ),
    );
  }
}
