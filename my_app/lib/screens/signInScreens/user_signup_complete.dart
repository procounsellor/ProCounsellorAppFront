import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';

import '../newCallingScreen/save_fcm_token.dart';

final storage = FlutterSecureStorage();

class SignUpCompleteScreen extends StatefulWidget {
  final String userId;
  final String jwtToken;
  final String firebaseCustomToken;
  final Future<void> Function() onSignOut;

  SignUpCompleteScreen(
      {required this.userId,
      required this.jwtToken,
      required this.firebaseCustomToken,
      required this.onSignOut});

  @override
  _SignUpCompleteScreenState createState() => _SignUpCompleteScreenState();
}

class _SignUpCompleteScreenState extends State<SignUpCompleteScreen> {
  @override
  void initState() {
    super.initState();
    _storeCredentials();
  }

  Future<void> _storeCredentials() async {
    await storage.write(key: "role", value: "user");
    await storage.write(key: "jwtToken", value: widget.jwtToken);
    await storage.write(key: "userId", value: widget.userId);
    // await FirestoreService.saveFCMTokenUser(widget.userId);
    // print(FirestoreService.getFCMTokenUser(widget.userId));


    // Authenticate with Firebase using the custom token
    await FirebaseAuth.instance
        .signInWithCustomToken(widget.firebaseCustomToken);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Authenticated user: ${user.uid}");
    } else {
      print("Authentication failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(seconds: 1),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.check_circle,
                color: Color(0xFFFAAF84),
                size: 100,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Congratulations!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFAAF84),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You have successfully signed up.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              "Phone Number: ${widget.userId}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFAAF84),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => BasePage(
                    username: widget.userId,
                    onSignOut: widget.onSignOut,
                  ),
                ),
                (route) => false,
              );
              },
              child: Text(
                "Go to Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
