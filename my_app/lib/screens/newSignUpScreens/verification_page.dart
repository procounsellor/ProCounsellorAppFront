import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/newSignUpScreens/get_user_details_step1.dart';
import 'package:my_app/screens/newSignUpScreens/new_signin_page.dart';
import 'package:my_app/screens/newSignUpScreens/user_details.dart';
import 'package:my_app/services/auth_service.dart';

final storage = FlutterSecureStorage();

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? phoneNumber = await storage.read(key: "phoneNumber");

    if (phoneNumber != null) {
      // Redirect to BasePage if session exists
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BasePage(
            onSignOut: _signOut,
            username: phoneNumber,
          ),
        ),
      );
    } else {
      // Redirect to the login page if no session exists
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NewSignInPage()),
      );
    }
  }

  void _signOut() async {
    await storage.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class VerificationPage extends StatefulWidget {
  final String phoneNumber;

  VerificationPage({required this.phoneNumber});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  List<String> otpDigits = List.filled(6, "");
  bool isButtonEnabled = false;
  final AuthService _apiService = AuthService();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Container(), // Disable back button in the AppBar
          backgroundColor: Colors.white,
          elevation: 0,
        ),
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
                  backgroundColor: isButtonEnabled ? Colors.orange.shade300 : Colors.grey,
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
      ),
    );
  }

  Future<void> _handleVerification() async {
    try {
      String otp = otpDigits.join();
      final response = await _apiService.verifyAndSignup(widget.phoneNumber, otp);

      if (response.statusCode == 201) {
        await storage.write(key: "phoneNumber", value: widget.phoneNumber);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BasePage(
              onSignOut: _signOut,
              username: widget.phoneNumber,
            ),
          ),
        );
      } else if (response.statusCode == 200) {
        final detailsResponse = await _apiService.isUserDetailsNull(widget.phoneNumber);

        if (detailsResponse.statusCode == 200 && detailsResponse.body == 'false') {
          await storage.write(key: "phoneNumber", value: widget.phoneNumber);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BasePage(
                onSignOut: _signOut,
                username: widget.phoneNumber,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GetUserDetailsStep1(
                userDetails: UserDetails(userInterestedStates: [], interestedCourse: null),
                phoneNumber: widget.phoneNumber,
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

  void _signOut() async {
    await storage.deleteAll();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => NewSignInPage()),
      (route) => false,
    );
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
