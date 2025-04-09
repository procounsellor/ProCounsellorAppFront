import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/screens/dashboards/adminDashboard/admin_signin.dart';
import 'package:ProCounsellor/screens/signInScreens/get_help.dart';
import 'package:ProCounsellor/screens/signInScreens/privacy_page.dart';
import 'package:ProCounsellor/screens/signInScreens/terms_page.dart';

import 'package:ProCounsellor/screens/signInScreens/verification_page.dart';
import 'package:ProCounsellor/screens/signInScreens/counsellor_signin.dart';
import 'package:ProCounsellor/screens/signInScreens/counsellor_signup.dart';
import 'package:ProCounsellor/services/api_utils.dart';

class UserSignInPage extends StatefulWidget {
  final Future<void> Function() onSignOut;

  UserSignInPage({required this.onSignOut});

  @override
  _UserSignInPageState createState() => _UserSignInPageState();
}

class _UserSignInPageState extends State<UserSignInPage> {
  final TextEditingController _phoneController = TextEditingController();
  String selectedCountryCode = '+91';
  bool isButtonEnabled = false;
  //bool isButtonEnabled = true; // Initially enabled
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        isButtonEnabled = _phoneController.text.length == 10;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/banner.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '  or  ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextSpan(
                    text: 'Signup',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCountryCode,
                    items: [
                      DropdownMenuItem(
                        value: '+91',
                        child: Text('+91'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCountryCode = value!;
                      });
                    },
                    underline: SizedBox(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter mobile number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(text: 'By continuing, I agree to the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TermsPage()),
                        );
                      },
                  ),
                  TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrivacyPage()),
                        );
                      },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isButtonEnabled
                  ? () {
                      String phoneNumber =
                          "$selectedCountryCode${_phoneController.text}";
                      generateOtp(phoneNumber);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    isButtonEnabled ? Colors.green[300] : Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
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
                  : Text('Get verification code'),
            ),
            SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(text: 'Facing issues logging in ? '),
                  TextSpan(
                    text: 'Get Help',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GetHelp()),
                        );
                      },
                  ),
                ],
              ),
            ),
            // Spacer(),
            // Image.asset(
            //   'assets/images/c3.png',

            //   height: 100,
            // ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      // MaterialPageRoute(
                                      //   builder: (_) => CounsellorSignUpStep1(
                                      //       signUpData: CounsellorSignUpData()),
                                      // ),
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CounsellorSignUpStepper(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFAAF84),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CounsellorSignInScreen(
                                            onSignOut: widget.onSignOut),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFAAF84),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign in',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminSignInScreen(
                                            onSignOut: widget.onSignOut),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFAAF84),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Admin Sign in',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                'SignIn as counsellor',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void generateOtp(String phoneNumber) async {
    try {
      setState(() {
        isLoading = true; // ✅ Show loader
        isButtonEnabled = false; // ✅ Disable button
      });
      //random code
      print("Phone number " + phoneNumber);
      //
      final response = await http.post(
        Uri.parse('${ApiUtils.baseUrl}/api/auth/generateOtp'),

        body: {'phoneNumber': phoneNumber},
      );
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false; // ✅ Show loader
          isButtonEnabled = true; // ✅ Disable button
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPage(
                phoneNumber: phoneNumber, onSignOut: widget.onSignOut),
          ),
        );
      } else {
        print('Failed to generate OTP: ${response.body}');
      }
    } catch (e) {
      print('Error calling API: $e');
    }
  }

  void generateOtpTest(String phoneNumber) async {
    try {
      setState(() {
        isLoading = true; // Start loading indicator
      });

      print("Phone number: $phoneNumber");

      // Simulate API delay of 2 seconds
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        isLoading = false; // Stop loading
      });

      // Navigate to VerificationPage after the delay
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(
            phoneNumber: phoneNumber,
            onSignOut: widget.onSignOut,
          ),
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }
}
