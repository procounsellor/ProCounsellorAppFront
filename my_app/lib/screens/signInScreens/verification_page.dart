import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/signInScreens/get_user_details_step1.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/signInScreens/user_details.dart';
import 'package:my_app/services/auth_service.dart';
import 'dart:convert';

final storage = FlutterSecureStorage();

class VerificationPage extends StatefulWidget {
  final String phoneNumber;

    final Future<void> Function() onSignOut;

  VerificationPage({required this.phoneNumber, required this.onSignOut});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  List<String> otpDigits = List.filled(6, "");
  bool isButtonEnabled = false;
  final FocusNode firstOtpFieldFocusNode = FocusNode();
  final AuthService _apiService = AuthService();

  @override
  void initState() {
    super.initState();
    firstOtpFieldFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              'Verification code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please enter the 6-digit code sent on ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 40,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    focusNode: index == 0 ? firstOtpFieldFocusNode : null,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        otpDigits[index] = value;
                        if (index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      } else {
                        otpDigits[index] = "";
                      }
                      setState(() {
                        isButtonEnabled = otpDigits.every((digit) => digit.isNotEmpty);
                      });
                    },
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isButtonEnabled ? () => _handleVerification() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? Colors.orange.shade300 : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _resendOtp(),
              child: Text('Resend OTP'),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerification() async {
    try {
      String otp = otpDigits.join();
      final response =
          await _apiService.verifyAndSignup(widget.phoneNumber, otp);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        String jwtToken = body['jwtToken'];
        String userId = body['userId'];
        String firebaseCustomToken = body['firebaseCustomToken'];
        String role = "user";

        if (response.statusCode == 200) {
          final detailsResponse = await _apiService.isUserDetailsNull(userId);

          if (detailsResponse.statusCode == 200 &&
              detailsResponse.body == 'false') {
            // Save role, JWT and userId in secure storage when signed in
            await storage.write(key: "role", value: role);
            await storage.write(key: "jwtToken", value: jwtToken);
            await storage.write(key: "userId", value: userId);

            // Authenticate with Firebase using the custom token
            await FirebaseAuth.instance
                .signInWithCustomToken(firebaseCustomToken);
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              print("Authenticated user: ${user.uid}");
            } else {
              print("Authentication failed.");
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BasePage(
                  onSignOut: widget.onSignOut,
                  username: userId,
                ),
              ),
              (route) => false, // Remove all previous routes
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GetUserDetailsStep1(
                  userDetails: UserDetails(
                      userInterestedStates: [], interestedCourse: null),
                  userId: userId,
                  jwtToken: jwtToken,
                  firebaseCustomToken: firebaseCustomToken,
                  onSignOut: widget.onSignOut,
                ),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GetUserDetailsStep1(
                userDetails: UserDetails(
                    userInterestedStates: [], interestedCourse: null),
                userId: userId,
                jwtToken: jwtToken,
                firebaseCustomToken: firebaseCustomToken,
                onSignOut: widget.onSignOut,
              ),
            ),
          );
        }
      } else {
        showErrorDialog('Invalid or expired OTP. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog('An error occurred. Please try again.');
    }
  }

  Future<void> _resendOtp() async {
    try {
      final response = await _apiService.generateOtp(widget.phoneNumber);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OTP sent successfully.'),
        ));
      } else {
        showErrorDialog('Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog('An error occurred. Please try again.');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
