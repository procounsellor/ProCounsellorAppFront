import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("About Us",
            style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''ProCounsellor is built with a mission to democratize career guidance. We aim to bridge the gap between aspiring individuals and experienced mentors by offering a secure, easy-to-use platform for live counselling sessions.

Founded by a team of educators and developers, ProCounsellor blends technology and empathy to ensure users get personalized support in their career journey.

We believe in privacy, simplicity, and meaningful human connections.''',
          style: GoogleFonts.outfit(fontSize: 16),
        ),
      ),
    );
  }
}
