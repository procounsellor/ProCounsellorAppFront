import 'package:flutter/material.dart';

class AdminProfilePage extends StatefulWidget {
   final VoidCallback onSignOut;
  final String adminId;

  AdminProfilePage({required this.onSignOut, required this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Welcome to the Admin Profile")),
    );
  }
}