import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboards/userDashboard/following_counsellors_page.dart';
import 'package:my_app/screens/dashboards/userDashboard/my_reviews.dart';
import 'subscribed_counsellors_page.dart';
import 'chat_page.dart';

class MyActivitiesPage extends StatelessWidget {
  final String username; // Added userId

  MyActivitiesPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Number of columns in the grid
          crossAxisSpacing: 16.0, // Horizontal spacing between items
          mainAxisSpacing: 16.0, // Vertical spacing between items
          children: [
            ActivityBox(
              imageAsset: 'images/c1.png',
              title: "Counsellors Subscribed",
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
              imageAsset: 'images/add-friend.png',
              title: "Counsellors Following",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FollowingCounsellorsPage(username: username),
                  ),
                );
              },
            ),
            ActivityBox(
              imageAsset: 'images/rating.png',
              title: "My Reviews",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyReviewPage(username: username),
                  ),
                );
              },
            ),
            ActivityBox(
              imageAsset: 'images/chat.png',
              title: "Chats",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(userId: username),
                  ),
                );
              },
            ),
            ActivityBox(
              imageAsset: 'images/call.png',
              title: "Calls (Video/Audio)",
              onTap: () {
                // Navigate to Calls Page
                Navigator.pushNamed(context, '/calls');
              },
            ),
            ActivityBox(
              imageAsset: 'images/play.png',
              title: "Liked Videos",
              onTap: () {
                // Navigate to Liked Videos Page
                Navigator.pushNamed(context, '/liked_videos');
              },
            ),
            ActivityBox(
              imageAsset: 'images/bookmarking.png',
              title: "Liked Articles",
              onTap: () {
                // Navigate to Liked Articles Page
                Navigator.pushNamed(context, '/liked_articles');
              },
            ),
            ActivityBox(
              imageAsset: 'images/article.png',
              title: "Saved Articles",
              onTap: () {
                // Navigate to Saved Articles Page
                Navigator.pushNamed(context, '/saved_articles');
              },
            ),
            ActivityBox(
              imageAsset: 'images/diversity.png',
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
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final VoidCallback onTap;

  ActivityBox(
      {this.icon, this.imageAsset, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Image.asset(
                  imageAsset!,
                  height: 50.0,
                  width: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            if (icon != null)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF0BB78),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40.0,
                  color: Colors.white,
                ),
              ),
            SizedBox(height: 12.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
