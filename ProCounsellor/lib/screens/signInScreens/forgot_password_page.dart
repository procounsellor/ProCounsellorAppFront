import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      // TODO: Implement password reset functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                child: Text('Reset Password'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
