import 'package:flutter/material.dart';
import 'package:my_app/screens/newSignUpScreens/get_user_details_step2.dart';
import 'package:my_app/screens/newSignUpScreens/user_details.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Your Interested Course",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCourse != null
                        ? Colors.green[300] // Light orange for enabled button
                        : Colors.grey, // Grey for disabled button
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
            ],
          ),
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
        width: MediaQuery.of(context).size.width *
            0.1, // Smaller width (60% reduction)
        height: MediaQuery.of(context).size.width *
            0.1, // Smaller height (60% reduction)
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFFFFF3E0) // Light orange background for selected
              : Colors.white, // White for unselected
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3), // Subtle shadow
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40, // Reduced size (50% of previous)
              color: isSelected
                  ? Color.fromARGB(255, 237, 110, 36)
                  : Colors.black, // Orange for selected, black for unselected
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFFFAAF84) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
