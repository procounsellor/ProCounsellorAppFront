import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:my_app/screens/newSignUpScreens/verification_page.dart';
import 'package:my_app/screens/oldSignUpScreens/counselllor_signup_step1.dart';
import 'package:my_app/screens/oldSignUpScreens/counsellor_signup_data.dart';
import 'package:my_app/screens/oldSignUpScreens/signin.dart';

class NewSignInPage extends StatefulWidget {
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
            SizedBox(height: 8),
            Text(
              'Your Counselling Expert',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
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
                    underline: SizedBox(), // Removes the default underline
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
                      // Call the generateOtp API and navigate to the verification page
                      String phoneNumber = "$selectedCountryCode${_phoneController.text}";
                      generateOtp(phoneNumber);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isButtonEnabled ? Colors.orange.shade300 : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Get verification code'),
            ),
            TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CounsellorSignUpStep1(signUpData: CounsellorSignUpData()),
                      ),
                    );
                  },
                  child: Text(
                    "Sign up as a Counsellor.",
                    style: TextStyle(color: Color(0xFFFAAF84), fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignInScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Sign in as a Counsellor.",
                    style: TextStyle(color: Color(0xFFFAAF84), fontSize: 16),
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
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/generateOtp'),
        body: {'phoneNumber': phoneNumber},
      );
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPage(phoneNumber: phoneNumber),
          ),
        );
      } else {
        print('Failed to generate OTP: ${response.body}');
        // Show an error message to the user
      }
    } catch (e) {
      print('Error calling API: $e');
      // Show an error message to the user
    }
  }
}
