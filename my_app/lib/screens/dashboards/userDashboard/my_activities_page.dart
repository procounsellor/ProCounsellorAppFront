import 'package:flutter/material.dart';
import 'subscribed_counsellors_page.dart';

class MyActivitiesPage extends StatelessWidget {
  final String username; // Added userId

  MyActivitiesPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Activities"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Number of columns in the grid
          crossAxisSpacing: 16.0, // Horizontal spacing between items
          mainAxisSpacing: 16.0, // Vertical spacing between items
          children: [
            ActivityBox(
              icon: Icons.person,
              title: "Subscribed Counsellors",
              onTap: () {
                // Pass userId to SubscribedCounsellorsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SubscribedCounsellorsPage(username: username),
                  ),
                );
              },
            ),
            ActivityBox(
              icon: Icons.chat,
              title: "Chats",
              onTap: () {
                // Navigate to Chats Page
                Navigator.pushNamed(context, '/chats');
              },
            ),
            ActivityBox(
              icon: Icons.call,
              title: "Calls (Video/Audio)",
              onTap: () {
                // Navigate to Calls Page
                Navigator.pushNamed(context, '/calls');
              },
            ),
            ActivityBox(
              icon: Icons.favorite,
              title: "Liked Videos",
              onTap: () {
                // Navigate to Liked Videos Page
                Navigator.pushNamed(context, '/liked_videos');
              },
            ),
            ActivityBox(
              icon: Icons.article,
              title: "Liked Articles",
              onTap: () {
                // Navigate to Liked Articles Page
                Navigator.pushNamed(context, '/liked_articles');
              },
            ),
            ActivityBox(
              icon: Icons.bookmark,
              title: "Saved Articles",
              onTap: () {
                // Navigate to Saved Articles Page
                Navigator.pushNamed(context, '/saved_articles');
              },
            ),
            ActivityBox(
              icon: Icons.groups,
              title: "My Communities",
              onTap: () {
                // Navigate to My Communities Page
                Navigator.pushNamed(context, '/my_communities');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  ActivityBox({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Color(0xFFF0BB78)),
            SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
