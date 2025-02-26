import 'package:flutter/material.dart';
import 'package:my_app/screens/signInScreens/get_user_details_step2.dart';
import 'package:my_app/screens/signInScreens/user_details.dart';

class GetUserDetailsStep1 extends StatefulWidget {
  final UserDetails userDetails;
  final String userId;
  final String jwtToken;
  final String firebaseCustomToken;

  final Future<void> Function() onSignOut;

  GetUserDetailsStep1({
    required this.userDetails,
    required this.userId,
    required this.jwtToken,
    required this.firebaseCustomToken,
    required this.onSignOut,
  });

  @override
  _GetUserDetailsStep1State createState() => _GetUserDetailsStep1State();
}

class _GetUserDetailsStep1State extends State<GetUserDetailsStep1> {
  String? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set entire background to white
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/banner3.png',
                    width: MediaQuery.of(context).size.width * 0.9,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Which course are you interested in ?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildPill("HSC"),
                  _buildPill("ENGINEERING"),
                  _buildPill("MEDICAL"),
                  _buildPill("MBA"),
                  _buildPill("OTHERS"),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCourse != null
                        ? Colors.green[300] // Enabled button
                        : Colors.grey, // Disabled button
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: _selectedCourse != null
                      ? () {
                          widget.userDetails.interestedCourse = _selectedCourse;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GetUserDetailsStep2(
                                userDetails: widget.userDetails,
                                userId: widget.userId,
                                jwtToken: widget.jwtToken,
                                firebaseCustomToken: widget.firebaseCustomToken,
                                onSignOut: widget.onSignOut,
                              ),
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
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Don't worry you can modify the choices later.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label) {
    final isSelected = _selectedCourse == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCourse = label;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : Colors.grey,
            width: 1.2,
          ),
          color: isSelected ? Colors.orangeAccent : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
