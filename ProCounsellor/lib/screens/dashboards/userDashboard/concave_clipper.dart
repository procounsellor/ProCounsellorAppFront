import 'package:flutter/material.dart';

class ConcaveBackgroundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Upper half background with concave edge
          ClipPath(
            clipper: ConcaveClipper(),
            child: Container(
              height:
                  MediaQuery.of(context).size.height * 0.5, // Upper half height
              color: Color(0xFFF0BB78), // Upper half color
            ),
          ),
          // Rest of the content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50), // Space for header
                Text(
                  "Which state are you looking for?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Add your other widgets (state tags, lists, etc.)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConcaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50); // Start from bottom-left
    path.quadraticBezierTo(
      size.width / 2, size.height, // Control point for the curve
      size.width, size.height - 50, // End point at bottom-right
    );
    path.lineTo(size.width, 0); // Top-right corner
    path.close(); // Complete the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false; // No need to reclip as the shape is static
  }
}
