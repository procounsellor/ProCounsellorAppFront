import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Privacy Policy",
            style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''At ProCounsellor, we prioritize your privacy. We collect minimal personal data such as name, email, and interaction logs to enhance your experience. All data is encrypted and never shared without consent. 

We use secure authentication, and communication is end-to-end encrypted, including chat and call functionalities. You can request deletion of your data anytime by contacting support.

By using our services, you agree to the collection and use of information in accordance with this policy.''',
          style: GoogleFonts.outfit(fontSize: 16),
        ),
      ),
    );
  }
}
