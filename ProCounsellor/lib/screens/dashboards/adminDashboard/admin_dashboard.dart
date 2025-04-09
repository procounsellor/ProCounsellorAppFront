import 'package:flutter/material.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/dashboard_button.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/get_all_counsellors.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/get_all_news.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/get_all_users.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/post_news.dart';

class AdminDashboard extends StatelessWidget {
  final VoidCallback onSignOut;
  final String adminId;

  AdminDashboard({required this.onSignOut, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DashboardButton(
              title: "View All Users",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllUsersPage()),
                );
              },
            ),
            DashboardButton(
              title: "View All Counsellors",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllCounsellorsPage()),
                );
              },
            ),
            DashboardButton(
              title: "View All News",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllNewsPage()),
                );
              },
            ),
            DashboardButton(
              title: "Post News",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddNewsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
