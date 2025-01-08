import 'package:flutter/material.dart';
import 'package:my_app/screens/oldSignUpScreens/user_signup_data.dart';
import 'package:my_app/screens/oldSignUpScreens/user_signup_step2.dart';

class UserSignUpStep1 extends StatefulWidget {
  final UserSignUpData signUpData;

  UserSignUpStep1({required this.signUpData});

  @override
  _UserSignUpStep1State createState() => _UserSignUpStep1State();
}

class _UserSignUpStep1State extends State<UserSignUpStep1> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5), // Lighter shade of orange
        title: Text(
          "Sign Up - Step 1",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Color(0xFFFFE4B5).withOpacity(0.3), // Semi-transparent orange
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Color(0xFFFFE4B5).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFAAF84), // Slightly darker shade of orange
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Let’s get you started",
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: "Username",
                          initialValue: widget.signUpData.username,
                          onSave: (value) => widget.signUpData.username = value,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: "First Name",
                          initialValue: widget.signUpData.firstName,
                          onSave: (value) => widget.signUpData.firstName = value,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: "Last Name",
                          initialValue: widget.signUpData.lastName,
                          onSave: (value) => widget.signUpData.lastName = value,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: "Phone Number",
                          initialValue: widget.signUpData.phoneNumber,
                          keyboardType: TextInputType.phone,
                          onSave: (value) => widget.signUpData.phoneNumber = value,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: "Email",
                          initialValue: widget.signUpData.email,
                          keyboardType: TextInputType.emailAddress,
                          onSave: (value) => widget.signUpData.email = value,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: "Password",
                          initialValue: widget.signUpData.password,
                          obscureText: true,
                          onSave: (value) => widget.signUpData.password = value,
                        ),
                        SizedBox(height: 40),
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
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserSignUpStep2(signUpData: widget.signUpData),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? initialValue,
    required Function(String?) onSave,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
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
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) => value!.isEmpty ? "Required" : null,
      onSaved: onSave,
    );
  }
}
