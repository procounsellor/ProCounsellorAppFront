import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/base_page.dart';
import 'package:ProCounsellor/screens/signInScreens/get_user_details_step1.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ProCounsellor/screens/signInScreens/user_details.dart';
import 'package:ProCounsellor/services/auth_service.dart';
import 'dart:convert';
import 'dart:async';

import '../newCallingScreen/save_fcm_token.dart';

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
  bool isLoading = false;
  final FocusNode firstOtpFieldFocusNode = FocusNode();
  final AuthService _apiService = AuthService();
  int _resendTimer = 18;
  bool _canResend = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    firstOtpFieldFocusNode.requestFocus();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        _timer.cancel();
        return;
      }
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    firstOtpFieldFocusNode.dispose(); // ✅ Dispose the focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 36),
          buildBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MOBILE NUMBER',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'EDIT',
                          style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "+91 " + widget.phoneNumber,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ONE TIME PASSWORD",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 40,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        // child: TextField(
                        //   focusNode: index == 0 ? firstOtpFieldFocusNode : null,
                        //   onChanged: (value) {
                        //     if (value.isNotEmpty) {
                        //       otpDigits[index] = value;
                        //       if (index < 5) {
                        //         FocusScope.of(context).nextFocus();
                        //       }
                        //     } else {
                        //       otpDigits[index] = "";
                        //     }
                        //     setState(() {
                        //       isButtonEnabled =
                        //           otpDigits.every((digit) => digit.isNotEmpty);
                        //     });
                        //   },
                        //   keyboardType: TextInputType.number,
                        //   textAlign: TextAlign.center,
                        //   maxLength: 1,
                        //   decoration: InputDecoration(
                        //     counterText: "",
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(4),
                        //     ),
                        //   ),
                        // ),
                        child: TextField(
                          focusNode: index == 0 ? firstOtpFieldFocusNode : null,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isEmpty && index > 0) {
                              FocusScope.of(context)
                                  .previousFocus(); // ⬅️ Go back if empty
                            } else if (value.isNotEmpty) {
                              otpDigits[index] = value;
                              if (index < 5) {
                                FocusScope.of(context)
                                    .nextFocus(); // ➡️ Go forward if typed
                              }
                            } else {
                              otpDigits[index] = "";
                            }
                            setState(() {
                              isButtonEnabled =
                                  otpDigits.every((digit) => digit.isNotEmpty);
                            });
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        isButtonEnabled ? () => _handleVerification() : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          isButtonEnabled ? Colors.green.shade300 : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('VERIFY OTP'),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't receive OTP? Resend in ",
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          TextSpan(
                            text: "$_resendTimer",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: " seconds",
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _resendTimer = 18;
                            _canResend = false;
                            _startResendTimer();
                          });
                        }
                        _resendOtp();
                      },
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Updated banner with card and rounded corners
  Widget buildBanner() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          'assets/images/banner2.png',
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Future<void> _handleVerification() async {
    try {
      setState(() {
        isLoading = true; // ✅ Show loader
        isButtonEnabled = false; // ✅ Disable button
      });
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
            await FirestoreService.saveFCMTokenUser(userId);
            print(FirestoreService.getFCMTokenUser(userId));

            // Authenticate with Firebase using the custom token
            await FirebaseAuth.instance
                .signInWithCustomToken(firebaseCustomToken);
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              print("Authenticated user: ${user.uid}");
            } else {
              print("Authentication failed.");
            }
            setState(() {
              isLoading = false; // ✅ Hide loader
              isButtonEnabled = true; // ✅ Re-enable button
            });
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
        setState(() {
          isLoading = false; // ✅ Hide loader
          isButtonEnabled = true; // ✅ Re-enable button
        });
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
