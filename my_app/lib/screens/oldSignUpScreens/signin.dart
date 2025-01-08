import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/oldSignUpScreens/counselllor_signup_step1.dart';
import 'package:my_app/screens/oldSignUpScreens/counsellor_signup_data.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:my_app/screens/oldSignUpScreens/user_signup_data.dart';
import 'package:my_app/screens/oldSignUpScreens/user_signup_step1.dart';
import '../../services/auth_service.dart';
import '../dashboards/userDashboard/base_page.dart';

final storage = FlutterSecureStorage();

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    final role = await storage.read(key: 'role');
    final username = await storage.read(key: 'username');
    if (role != null && username != null) {
      _navigateToDashboard(role, username);
    }
  }

  Future<void> _signIn() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final role = await AuthService.signIn(username, password);
    if (role == 'user' || role == 'counsellor' || role == 'admin') {
      await storage.write(key: 'role', value: role);
      await storage.write(key: 'username', value: username);
      _navigateToDashboard(role, username);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(role)));
    }
  }

  void _navigateToDashboard(String role, String username) {
    Widget dashboard;
    if (role == 'user') {
      dashboard = BasePage(
          onSignOut: _signOut,
          username: username); // Use BasePage for all roles
    } else if (role == 'counsellor') {
      dashboard = CounsellorBasePage(
          onSignOut: _signOut, counsellorId: username); // For counsellors
    } else if (role == 'admin') {
      dashboard =
          BasePage(onSignOut: _signOut, username: username); // For admin
    } else {
      return;
    }

    // Navigate and remove previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false, // Remove all previous routes to prevent back navigation
    );
  }

  void _signOut() async {
    await storage.deleteAll(); // Clear all data from secure storage

    if (!mounted) return; // Check if widget is still mounted

    // Navigate to SignInScreen and clear the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5),
        title: Text(
          "Sign In",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Color(0xFFFAAF84)),
                    filled: true,
                    fillColor: Color(0xFFFFF8EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Color(0xFFFAAF84)),
                    filled: true,
                    fillColor: Color(0xFFFFF8EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFFFAAF84), width: 2),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFAAF84),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _signIn,
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserSignUpStep1(signUpData: UserSignUpData()),
                      ),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Color(0xFFFAAF84), fontSize: 16),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
