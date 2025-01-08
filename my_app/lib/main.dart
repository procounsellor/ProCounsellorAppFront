import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/newSignUpScreens/new_signin_page.dart';
import 'package:firebase_core/firebase_core.dart';

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch stored token and phone number
  String? jwtToken = await storage.read(key: "jwtToken");
  String? phoneNumber = await storage.read(key: "phoneNumber");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCFKdFziXt7j7wsoCHZ1nWChoKsy6cCj8U",
      authDomain: "procounsellor-71824.firebaseapp.com",
      projectId: "procounsellor-71824",
      storageBucket: "procounsellor-71824.appspot.com",
      messagingSenderId: "1000407154647",
      appId: "1:1000407154647:web:0cc6c26e11d212a233d592",
      databaseURL: "https://procounsellor-71824-default-rtdb.firebaseio.com",
    ),
  );

  runApp(ProCounsellorApp(jwtToken: jwtToken, phoneNumber: phoneNumber));
}

class ProCounsellorApp extends StatelessWidget {
  final String? jwtToken;
  final String? phoneNumber;

  ProCounsellorApp({this.jwtToken, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppInitializer(jwtToken: jwtToken, phoneNumber: phoneNumber),
    );
  }
}

class AppInitializer extends StatelessWidget {
  final String? jwtToken;
  final String? phoneNumber;

  AppInitializer({this.jwtToken, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    // Redirect based on authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (jwtToken != null && jwtToken!.isNotEmpty && phoneNumber != null && phoneNumber!.isNotEmpty) {
        // Navigate to dashboard and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              username: phoneNumber!,
              onSignOut: () async {
                await storage.deleteAll();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ),
          (route) => false, // Clear previous stack
        );
      } else {
        // Navigate to login screen and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NewSignInPage()),
          (route) => false,
        );
      }
    });

    // Return a temporary loading screen
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
