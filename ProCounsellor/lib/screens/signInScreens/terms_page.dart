import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(child: Text('This is the Terms and Conditions page.')),
    );
  }
}