import 'package:flutter/material.dart';
import 'screens/signin.dart';

void main() => runApp(ProCounsellorApp());

class ProCounsellorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProCounsellor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SignInScreen(),
    );
  }
}
