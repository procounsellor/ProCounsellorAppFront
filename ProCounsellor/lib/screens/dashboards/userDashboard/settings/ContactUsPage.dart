import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Contact Us",
            style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''Need help or want to collaborate?

📧 Email: counsellorpro@gmail.com
📞 Phone: +91-7004789484, +91-9470988669
📍 Address: The Address Commercia, Wakad, Hinjewadi, Pune.

We typically respond within 24–48 hours. Your feedback and suggestions help us improve — reach out anytime!''',
          style: GoogleFonts.outfit(fontSize: 16),
        ),
      ),
    );
  }
}
