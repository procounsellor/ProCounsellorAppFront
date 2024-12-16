import 'package:flutter/material.dart';

class MyActivitiesPage extends StatelessWidget {
  final String username;

  MyActivitiesPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Activities"),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ActivityTile(
            icon: Icons.chat,
            title: "Chats",
            onTap: () {
              // Navigate to Chats Page
              Navigator.pushNamed(context, '/chats');
            },
          ),
          ActivityTile(
            icon: Icons.call,
            title: "Calls (Video/Audio)",
            onTap: () {
              // Navigate to Calls Page
              Navigator.pushNamed(context, '/calls');
            },
          ),
          ActivityTile(
            icon: Icons.favorite,
            title: "Liked Videos",
            onTap: () {
              // Navigate to Liked Videos Page
              Navigator.pushNamed(context, '/liked_videos');
            },
          ),
          ActivityTile(
            icon: Icons.article,
            title: "Liked Articles",
            onTap: () {
              // Navigate to Liked Articles Page
              Navigator.pushNamed(context, '/liked_articles');
            },
          ),
          ActivityTile(
            icon: Icons.bookmark,
            title: "Saved Articles",
            onTap: () {
              // Navigate to Saved Articles Page
              Navigator.pushNamed(context, '/saved_articles');
            },
          ),
          ActivityTile(
            icon: Icons.groups,
            title: "My Communities",
            onTap: () {
              // Navigate to My Communities Page
              Navigator.pushNamed(context, '/my_communities');
            },
          ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  ActivityTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFF0BB78)),
        title: Text(title, style: TextStyle(fontSize: 18.0)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
