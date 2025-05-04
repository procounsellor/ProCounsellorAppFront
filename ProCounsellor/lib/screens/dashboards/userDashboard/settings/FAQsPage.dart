import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("FAQs", style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          faq("1. What is ProCounsellor?",
              "ProCounsellor is a platform that connects you with verified career counsellors for guidance, chat, and video consultations."),
          faq("2. How do I book a session?",
              "You can subscribe to a counsellor and initiate chat or calls from their profile page."),
          faq("3. Are calls recorded?",
              "No, all communication is private and encrypted."),
          faq("4. How do I update my profile?",
              "Go to the Profile tab and tap 'Complete Your Profile' to update your photo and details."),
          faq("5. Is there a refund policy?",
              "Currently, subscriptions are non-refundable once activated."),
        ],
      ),
    );
  }

  Widget faq(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(answer,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}
