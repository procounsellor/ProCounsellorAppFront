import 'package:flutter/material.dart';

class DashboardButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  DashboardButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }
}