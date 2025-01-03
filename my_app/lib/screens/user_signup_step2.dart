import 'package:flutter/material.dart';
import 'package:my_app/screens/user_signup_data.dart';
import 'package:my_app/screens/user_signup_step3.dart';

class UserSignUpStep2 extends StatefulWidget {
  final UserSignUpData signUpData;

  UserSignUpStep2({required this.signUpData});

  @override
  _UserSignUpStep2State createState() => _UserSignUpStep2State();
}

class _UserSignUpStep2State extends State<UserSignUpStep2> {
  String? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5), // Lighter shade of orange
        title: Text(
          "Sign Up - Step 2",
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
                    "Choose Your Interested Course",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFAAF84), // Slightly darker shade of orange
                    ),
                  ),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildOption("HSC", Icons.school, "HSC"),
                      _buildOption("ENGINEERING", Icons.engineering, "ENGINEERING"),
                      _buildOption("MEDICAL", Icons.local_hospital, "MEDICAL"),
                      _buildOption("MBA", Icons.business, "MBA"),
                      _buildOption("OTHERS", Icons.more_horiz, "OTHERS"),
                    ],
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCourse != null
                            ? Color(0xFFFAAF84)
                            : Colors.grey,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _selectedCourse != null
                          ? () {
                              widget.signUpData.interestedCourse = _selectedCourse;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserSignUpStep3(
                                      signUpData: widget.signUpData),
                                ),
                              );
                            }
                          : null,
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

  Widget _buildOption(String label, IconData icon, String value) {
    final isSelected = _selectedCourse == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCourse = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFAAF84).withOpacity(0.8) : Color(0xFFFFF8EE),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Color(0xFFFAAF84) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Color(0xFFFAAF84),
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Color(0xFFFAAF84),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
