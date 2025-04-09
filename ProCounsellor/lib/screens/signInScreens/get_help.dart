import 'package:flutter/material.dart';

class GetHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQs'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(child: Text('This is frequently asked questions page.')),
    );
  }
}