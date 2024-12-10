import 'package:flutter/material.dart';
import 'signup.dart';
import 'dashboards/user_dashboard.dart';
import 'dashboards/counsellor_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final role = await AuthService.signIn(username, password);
    if (role == 'user') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserDashboard()));
    } else if (role == 'counsellor') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CounsellorDashboard()));
    } else if (role == 'admin') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(role)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen()));
              },
              child: Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
