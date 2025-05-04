import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Terms & Conditions",
            style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''By registering with ProCounsellor, you agree to provide accurate details. Counselling sessions and content shared are strictly for personal development purposes.

You must not misuse the chat, call, or video features. Any abuse, spam, or fraudulent activity will lead to permanent suspension.

ProCounsellor reserves the right to modify these terms at any time with prior notice.''',
          style: GoogleFonts.outfit(fontSize: 16),
        ),
      ),
    );
  }
}
