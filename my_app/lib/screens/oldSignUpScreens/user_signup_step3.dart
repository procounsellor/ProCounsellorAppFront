import 'package:flutter/material.dart';
import 'package:my_app/screens/oldSignUpScreens/user_signup_data.dart';
import 'package:my_app/screens/oldSignUpScreens/signup_success.dart';
import 'package:my_app/services/auth_service.dart';

class UserSignUpStep3 extends StatefulWidget {
  final UserSignUpData signUpData;

  UserSignUpStep3({required this.signUpData});

  @override
  _UserSignUpStep3State createState() => _UserSignUpStep3State();
}

class _UserSignUpStep3State extends State<UserSignUpStep3> {
  final List<Map<String, String>> allowedStates = [
    {'name': 'KARNATAKA', 'image': 'assets/images/karnataka.jpg'},
    {'name': 'MAHARASHTRA', 'image': 'assets/images/maharashtra.jpg'},
    {'name': 'TAMILNADU', 'image': 'assets/images/tamilnadu.jpg'},
    {'name': 'OTHERS', 'image': 'assets/images/others.jpg'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE4B5),
        title: Text(
          "Sign Up - Step 3",
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
                  color: Color(0xFFFFE4B5).withOpacity(0.3),
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
                    "Select Interested States",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFAAF84),
                    ),
                  ),
                  SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: allowedStates.map((state) {
                      final isSelected = widget.signUpData.userInterestedStates.contains(state['name']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              widget.signUpData.userInterestedStates.remove(state['name']);
                            } else {
                              widget.signUpData.userInterestedStates.add(state['name']!);
                            }
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  state['image']!,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                state['name']!,
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
                    }).toList(),
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
                      onPressed: () async {
                        try {
                          await AuthService.userSignUp(
                            widget.signUpData.username!,
                            widget.signUpData.firstName!,
                            widget.signUpData.lastName!,
                            widget.signUpData.phoneNumber!,
                            widget.signUpData.email!,
                            widget.signUpData.password!,
                            widget.signUpData.role!,
                            widget.signUpData.userInterestedStates,
                            widget.signUpData.interestedCourse!,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpSuccessScreen(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sign Up Failed: $e")),
                          );
                        }
                      },
                      child: Text(
                        "Sign Up",
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
}