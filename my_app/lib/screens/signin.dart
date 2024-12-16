import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup.dart';
import '../services/auth_service.dart';
import 'dashboards/userDashboard/base_page.dart';

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
      dashboard =
          BasePage(onSignOut: _signOut, username: username); // For counsellors
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
      appBar: AppBar(title: Text("Sign In")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          // Using 'children' here
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              child: Text("Sign In"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SignUpScreen()));
              },
              child: Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
