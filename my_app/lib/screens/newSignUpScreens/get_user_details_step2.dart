import 'package:flutter/material.dart';
import 'package:my_app/screens/newSignUpScreens/signup_complete.dart';
import 'package:my_app/screens/newSignUpScreens/user_details.dart';
import 'package:my_app/services/auth_service.dart';

class GetUserDetailsStep2 extends StatefulWidget {
  final UserDetails userDetails;
  final String userId;
  final String jwtToken;
  final String firebaseCustomToken;
  final Future<void> Function() onSignOut;

  GetUserDetailsStep2({required this.userDetails, required this.userId, required this.jwtToken, required this.firebaseCustomToken, required this.onSignOut});

  @override
  _GetUserDetailsStep2State createState() => _GetUserDetailsStep2State();
}

class _GetUserDetailsStep2State extends State<GetUserDetailsStep2> {
  final List<Map<String, String>> allowedStates = [
    {'name': 'KARNATAKA', 'image': 'assets/images/karnataka.jpg'},
    {'name': 'MAHARASHTRA', 'image': 'assets/images/maharashtra.jpg'},
    {'name': 'TAMILNADU', 'image': 'assets/images/tamilnadu.jpg'},
    {'name': 'OTHERS', 'image': 'assets/images/others.jpg'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      final isSelected = widget.userDetails.userInterestedStates.contains(state['name']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              widget.userDetails.userInterestedStates.remove(state['name']);
                            } else {
                              widget.userDetails.userInterestedStates.add(state['name']!);
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
                          await AuthService.updateUserDetails(
                            widget.userId,
                            widget.userDetails.userInterestedStates,
                            widget.userDetails.interestedCourse!,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpCompleteScreen(userId: widget.userId, jwtToken: widget.jwtToken, firebaseCustomToken: widget.firebaseCustomToken, onSignOut: widget.onSignOut),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sign Up Failed: $e")),
                          );
                        }
                      },

                      child: Text(
                        "Submit",
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