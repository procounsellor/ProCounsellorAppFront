import 'package:flutter/material.dart';
import 'Articles/stress_articles_section.dart';
import 'Button/stress_connect_button.dart';
import 'Videos/stress_videos_section.dart';

class StressManagementPage extends StatelessWidget {
  const StressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.black), // back button in black
        title: null, // no title text
      ),
      body: Column(
        children: const [
          StressVideosSection(),
          StressArticlesSection(),
          StressConnectButton(),
        ],
      ),
    );
  }
}
