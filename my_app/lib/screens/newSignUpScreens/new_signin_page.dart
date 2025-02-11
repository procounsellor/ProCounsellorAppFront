import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/dashboards/adminDashboard/admin_signin.dart';

import 'package:my_app/screens/newSignUpScreens/verification_page.dart';
import 'package:my_app/screens/oldSignUpScreens/counselllor_signup_step1.dart';
import 'package:my_app/screens/oldSignUpScreens/counsellor_signup_data.dart';
import 'package:my_app/screens/oldSignUpScreens/counsellor_signin.dart';
import 'package:my_app/screens/oldSignUpScreens/SignUpController.dart';

class NewSignInPage extends StatefulWidget {
  final Future<void> Function() onSignOut;

  NewSignInPage({required this.onSignOut});

  @override
  _NewSignInPageState createState() => _NewSignInPageState();
}

class _NewSignInPageState extends State<NewSignInPage> {
  final TextEditingController _phoneController = TextEditingController();
  String selectedCountryCode = '+91';
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        isButtonEnabled = _phoneController.text.isNotEmpty;
      });
    });
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
              'Pro Counsellor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your Counselling Expert',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isButtonEnabled
                  ? () {
                      String phoneNumber =
                          "$selectedCountryCode${_phoneController.text}";
                      generateOtp(phoneNumber);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? Colors.orange.shade300 : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Get verification code'),
            ),
            Spacer(),
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
                  color: Colors.blue.shade300,
                  fontSize: 16,
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  void generateOtp(String phoneNumber) async {
    try {
      //random code

      //
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/generateOtp'),
        body: {'phoneNumber': phoneNumber},
      );
      if (response.statusCode == 200) {
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
}
