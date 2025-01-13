import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:my_app/screens/newSignUpScreens/new_signin_page.dart';
import 'package:firebase_core/firebase_core.dart';

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCFKdFziXt7j7wsoCHZ1nWChoKsy6cCj8U",
      authDomain: "procounsellor-71824.firebaseapp.com",
      projectId: "procounsellor-71824",
      storageBucket: "procounsellor-71824.firebasestorage.app",
      messagingSenderId: "1000407154647",
      appId: "1:1000407154647:web:0cc6c26e11d212a233d592",
      databaseURL: "https://procounsellor-71824-default-rtdb.firebaseio.com",
    ),
  );

  runApp(AppRoot());
}

class AppRoot extends StatefulWidget {
  @override
  _AppRootState createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? jwtToken;
  String? userId;
  String? role;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    jwtToken = await storage.read(key: "jwtToken");
    userId = await storage.read(key: "userId");
    role = await storage.read(key: "role");
    setState(() {});
  }

  Future<void> restartApp() async {
    await storage.deleteAll();

    setState(() {
      jwtToken = null;
      userId = null;
      role = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (jwtToken == null || jwtToken!.isEmpty || userId == null) {
      // Show login page if the token or userId is not present
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: NewSignInPage(
          onSignOut: restartApp,
        ),
      );
    }

    // Navigate based on role
    switch (role) {
      case "user":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BasePage(
            username: userId!,
            onSignOut: restartApp,
          ),
        );
      case "counsellor":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: CounsellorBasePage(
            onSignOut: restartApp,
            counsellorId: userId!
          ),
        );
      default:
        return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Invalid Role. Please contact support.",
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), // Add spacing between text and button
            ElevatedButton(
              onPressed: () {
                restartApp();
              },
              child: Text("Go to Login"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    ),
  );
    }
  }
}
