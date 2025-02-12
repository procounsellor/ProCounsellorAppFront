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
      backgroundColor: Colors.white, // Soft background color
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Create an Account",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Let’s get started with your details",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      label: "First Name",
                      initialValue: widget.signUpData.firstName,
                      onSave: (value) => widget.signUpData.firstName = value,
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      label: "Last Name",
                      initialValue: widget.signUpData.lastName,
                      onSave: (value) => widget.signUpData.lastName = value,
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF8EE),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            "+91",
                            style: TextStyle(
                              color: Colors.orange,
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
                            onSave: (value) =>
                                widget.signUpData.phoneNumber = "+91$value",
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      label: "Email",
                      initialValue: widget.signUpData.email,
                      keyboardType: TextInputType.emailAddress,
                      onSave: (value) => widget.signUpData.email = value,
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      label: "Password",
                      initialValue: widget.signUpData.password,
                      obscureText: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      onSave: (value) => widget.signUpData.password = value,
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      label: "Rate per Year",
                      initialValue: widget.signUpData.ratePerYear?.toString(),
                      keyboardType: TextInputType.number,
                      onSave: (value) => widget.signUpData.ratePerYear =
                          value != null ? double.tryParse(value) : null,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
            ),
          ),
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
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.orange),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.orange, width: 2),
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
