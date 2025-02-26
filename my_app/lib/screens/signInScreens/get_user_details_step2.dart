import 'package:flutter/material.dart';
import 'package:my_app/screens/signInScreens/user_signup_complete.dart';
import 'package:my_app/screens/signInScreens/user_details.dart';
import 'package:my_app/services/auth_service.dart';

class GetUserDetailsStep2 extends StatefulWidget {
  final UserDetails userDetails;
  final String userId;
  final String jwtToken;
  final String firebaseCustomToken;
  final Future<void> Function() onSignOut;

  GetUserDetailsStep2({
    required this.userDetails,
    required this.userId,
    required this.jwtToken,
    required this.firebaseCustomToken,
    required this.onSignOut,
  });

  @override
  _GetUserDetailsStep2State createState() => _GetUserDetailsStep2State();
}

class _GetUserDetailsStep2State extends State<GetUserDetailsStep2> {
  final List<Map<String, String>> allowedStates = [
    {'name': 'KARNATAKA', 'image': 'assets/images/kar.png'},
    {'name': 'MAHARASHTRA', 'image': 'assets/images/maha.png'},
    {'name': 'TAMILNADU', 'image': 'assets/images/tamil.png'},
    {'name': 'OTHERS', 'image': 'assets/images/indian.png'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/banner4.png',
                    width: MediaQuery.of(context).size.width * 0.9,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Select Interested States",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black, // Heading color set to black
                  ),
                ),
              ),
              SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                shrinkWrap:
                    true, // Prevent GridView from taking infinite height
                physics: NeverScrollableScrollPhysics(), // Grid doesn't scroll
                children: allowedStates.map((state) {
                  final isSelected = widget.userDetails.userInterestedStates
                      .contains(state['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          widget.userDetails.userInterestedStates
                              .remove(state['name']);
                        } else {
                          widget.userDetails.userInterestedStates
                              .add(state['name']!);
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              state['image']!,
                              fit: BoxFit
                                  .cover, // Ensures the image fills the card
                              width: MediaQuery.sizeOf(context).width / 2 - 58,
                              height: MediaQuery.sizeOf(context).width / 2 - 70,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.grey.shade300,
                        ),
                        SizedBox(height: 8), // Space between card and text
                        Text(
                          state['name']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color:
                                isSelected ? Colors.orangeAccent : Colors.black,
                          ),
                        ),
                        SizedBox(height: 20), // Extra spacing below each item
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green[300], // Submit button color set to green
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                          builder: (context) => SignUpCompleteScreen(
                            userId: widget.userId,
                            jwtToken: widget.jwtToken,
                            firebaseCustomToken: widget.firebaseCustomToken,
                            onSignOut: widget.onSignOut,
                          ),
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
      ),
    );
  }
}
