import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Dashboard")),
      body: Center(child: Text("Welcome to User Dashboard")),
    );
  }
}
