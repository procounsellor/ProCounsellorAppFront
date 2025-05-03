import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:ProCounsellor/screens/signInScreens/counsellor_signup.dart';
import 'package:ProCounsellor/screens/signInScreens/forgot_password_page.dart';
import '../../services/auth_service.dart';
import '../newCallingScreen/save_fcm_token.dart';
import '../../services/api_utils.dart';
import 'package:http/http.dart' as http;

final storage = FlutterSecureStorage();

class CounsellorSignInScreen extends StatefulWidget {
  final Future<void> Function() onSignOut;

  CounsellorSignInScreen({required this.onSignOut});
  @override
  _CounsellorSignInScreenState createState() => _CounsellorSignInScreenState();
}

class _CounsellorSignInScreenState extends State<CounsellorSignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _apiService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.counsellorSignIn(
          _usernameController.text, _passwordController.text);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        String jwtToken = body['jwtToken'];
        String userId = body['userId'];
        String firebaseCustomToken = body['firebaseCustomToken'];
        String role = "counsellor";

        // if (response.statusCode == 200) {
        //   // Save role, JWT and userId in secure storage when signed in
        //   await storage.write(key: "role", value: role);
        //   await storage.write(key: "jwtToken", value: jwtToken);
        //   await storage.write(key: "userId", value: userId);
        //   await FirestoreService.saveFCMTokenCounsellor(userId);
        //   print(FirestoreService.getFCMTokenCounsellor(userId));

        //   // Authenticate with Firebase using the custom token
        //   await FirebaseAuth.instance
        //       .signInWithCustomToken(firebaseCustomToken);
        //   User? user = FirebaseAuth.instance.currentUser;
        //   if (user != null) {
        //     print("Authenticated user: ${user.uid}");
        //   } else {
        //     print("Authentication failed.");
        //   }

        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => CounsellorBasePage(
        //         onSignOut: widget.onSignOut,
        //         counsellorId: userId,
        //       ),
        //     ),
        //     (route) => false,
        //   );
        // }

        if (response.statusCode == 200) {
          // Save role, JWT and userId in secure storage when signed in
          await storage.write(key: "role", value: role);
          await storage.write(key: "jwtToken", value: jwtToken);
          await storage.write(key: "userId", value: userId);
          await FirestoreService.saveFCMTokenCounsellor(userId);
          print(FirestoreService.getFCMTokenCounsellor(userId));

          // Authenticate with Firebase using the custom token
          await FirebaseAuth.instance
              .signInWithCustomToken(firebaseCustomToken);
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            print("Authenticated user: ${user.uid}");
          } else {
            print("Authentication failed.");
          }

          // 🔍 Fetch counsellor details to check if verified
          final counsellorResponse = await http.get(
            Uri.parse('${ApiUtils.baseUrl}/api/counsellor/$userId'),
            headers: {
              'Authorization': 'Bearer $jwtToken'
            }, // optional if required
          );

          if (counsellorResponse.statusCode == 200) {
            final counsellorData = json.decode(counsellorResponse.body);
            final isVerified = counsellorData['verified'] == true;

            if (isVerified) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => CounsellorBasePage(
                    onSignOut: widget.onSignOut,
                    counsellorId: userId,
                  ),
                ),
                (route) => false,
              );
            } else {
              // Show "under review" dialog or redirect to an UnderReviewPage
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Account Under Review"),
                  content: Text(
                      "Your counsellor profile is under review. Please wait for admin approval."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            }
          } else {
            // Show error if counsellor fetch failed
            print(
                "Failed to fetch counsellor details: ${counsellorResponse.statusCode}");
            // Optionally show a snackbar or dialog
          }
        }
      } else {
        showErrorDialog('Invalid Credentials. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/login_illustration.png',
                  height: 200,
                ),
                SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     ElevatedButton.icon(
                        //       onPressed: () {},
                        //       icon: Icon(Icons.g_mobiledata),
                        //       label: Text("Google"),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.redAccent,
                        //         foregroundColor: Colors.white,
                        //       ),
                        //     ),
                        //     SizedBox(width: 10),
                        //     ElevatedButton.icon(
                        //       onPressed: () {},
                        //       icon: Icon(Icons.facebook),
                        //       label: Text("Facebook"),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.blueAccent,
                        //         foregroundColor: Colors.white,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "Email/Phone Number",
                            prefixIcon: Icon(Icons.email, color: Colors.orange),
                            filled: true,
                            fillColor: Colors.orange.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock, color: Colors.orange),
                            filled: true,
                            fillColor: Colors.orange.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: Text("Forgot Password?"),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleVerification,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "SIGN IN",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 10),
                        Text("Not registered? ",
                            style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CounsellorSignUpStepper()),
                            );
                          },
                          child: Text("Create Account",
                              style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
