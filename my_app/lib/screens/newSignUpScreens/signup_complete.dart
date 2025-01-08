import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/newSignUpScreens/new_signin_page.dart';

final storage = FlutterSecureStorage();

class SignUpCompleteScreen extends StatelessWidget {
  final String phoneNumber;

  SignUpCompleteScreen({required this.phoneNumber});

  Future<void> _handleSignOut(BuildContext context) async {
    await storage.deleteAll(); // Clear session data

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => NewSignInPage()),
      (route) => false, // Remove all previous routes
    );
  }

  Future<void> _navigateToBasePage(BuildContext context) async {
    // Save session data
    await storage.write(key: "phoneNumber", value: phoneNumber);

    // Redirect to BasePage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BasePage(
          username: phoneNumber,
          onSignOut: () => _handleSignOut(context),
        ),
      ),
      (route) => false, // Prevent back navigation from BasePage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true, // Allow back navigation for other cases
        backgroundColor: Color(0xFFFFE4B5),
        title: Text(
          "Sign Up Successful",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
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
              "Phone Number: $phoneNumber",
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
              onPressed: () => _navigateToBasePage(context), // Navigate to BasePage
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
