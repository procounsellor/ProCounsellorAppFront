import 'package:flutter/material.dart';
import 'package:my_app/screens/oldSignUpScreens/counselllor_signup_step2.dart';
import 'package:my_app/screens/oldSignUpScreens/counsellor_signup_data.dart';

class CounsellorSignUpStep1 extends StatefulWidget {
  final CounsellorSignUpData signUpData;

  CounsellorSignUpStep1({required this.signUpData});

  @override
  _CounsellorSignUpStep1State createState() => _CounsellorSignUpStep1State();
}

class _CounsellorSignUpStep1State extends State<CounsellorSignUpStep1> {
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Plain white background
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5),
        title: Text(
          "Sign Up",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFAAF84),
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
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF8EE),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color(0xFFFAAF84),
                          ),
                        ),
                        child: Text(
                          "+91",
                          style: TextStyle(
                            color: Color(0xFFFAAF84),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildTextField(
                          label: "Phone Number",
                          initialValue: widget.signUpData.phoneNumber,
                          keyboardType: TextInputType.phone,
                          onSave: (value) => widget.signUpData.phoneNumber =
                              "+91$value",
                        ),
                      ),
                    ],
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
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFFFAAF84),
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    onSave: (value) => widget.signUpData.password = value,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: "Rate per Year",
                    initialValue: widget.signUpData.ratePerYear?.toString(),
                    keyboardType: TextInputType.number,
                    onSave: (value) => widget.signUpData.ratePerYear =
                        value != null ? double.tryParse(value) : null,
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
                              builder: (context) => CounsellorSignUpStep2(
                                signUpData: widget.signUpData,
                              ),
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
    );
  }

  Widget _buildTextField({
    required String label,
    required String? initialValue,
    required Function(String?) onSave,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
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
        suffixIcon: suffixIcon,
      ),
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ?? (value) => value!.isEmpty ? "Required" : null,
      onSaved: onSave,
    );
  }
}
