import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'my_activities_page.dart'; // Import My Activities Page
import 'learn_with_us_page.dart'; // Import Learn with Us Page
import 'community_page.dart'; // Import Community Page
import 'profile_page.dart'; // Import Profile Page

class BasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String username;

  BasePage({required this.onSignOut, required this.username});

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;

  // Define the pages that can be navigated to
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Initialize the pages with dynamic data
    _pages.add(UserDashboard(
        onSignOut: widget.onSignOut,
        username: widget.username)); // User Dashboard
    _pages.add(LearnWithUsPage()); // Learn with Us Page
    _pages.add(CommunityPage()); // Community Page
    _pages
        .add(MyActivitiesPage(username: widget.username)); // My Activities Page
    _pages.add(ProfilePage(username: widget.username)); // Profile Page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pro Counsellor",
          style: TextStyle(
              color: Color(0xFFF0BB78)), // Set the title color to #F0BB78
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: widget.onSignOut, // Call sign-out function
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78), // Color for selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb), label: "Learn with Us"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "My Activities"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
