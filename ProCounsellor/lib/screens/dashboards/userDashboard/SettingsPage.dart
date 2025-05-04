import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../userDashboard/settings/AboutUsPage.dart';
import '../userDashboard/settings/PrivacyPolicyPage.dart';
import '../userDashboard/settings/TermsAndConditionsPage.dart';
import '../userDashboard/settings/FAQsPage.dart';

import '../userDashboard/settings/ContactUsPage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onOptionTap(BuildContext context, String title) {
    Widget page;

    switch (title) {
      case 'Privacy Policy':
        page = const PrivacyPolicyPage();
        break;
      case 'Terms and Conditions':
        page = const TermsAndConditionsPage();
        break;
      case 'FAQs':
        page = const FAQsPage();
        break;
      case 'About Us':
        page = const AboutUsPage();
        break;
      case 'Contact Us':
        page = const ContactUsPage();
        break;
      default:
        page = Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text('Coming soon...')),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionStyle = GoogleFonts.outfit(fontSize: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text("SETTINGS",
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.grey[800])),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('Privacy Policy', style: optionStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onOptionTap(context, 'Privacy Policy'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('Terms and Conditions', style: optionStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onOptionTap(context, 'Terms and Conditions'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('FAQs', style: optionStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onOptionTap(context, 'FAQs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About Us', style: optionStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onOptionTap(context, 'About Us'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_mail_outlined),
            title: Text('Contact Us', style: optionStyle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onOptionTap(context, 'Contact Us'),
          ),
        ],
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  final String title;

  const InfoPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(color: Colors.grey[800])),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Text('Content for $title coming soon...',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black54)),
      ),
    );
  }
}
