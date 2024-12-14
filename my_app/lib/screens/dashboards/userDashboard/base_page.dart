import 'package:flutter/material.dart';
import 'call_page.dart'; // Import CallPage
import 'chat_page.dart'; // Import ChatPage
import 'user_dashboard.dart'; // Import UserDashboard or other pages

class BasePage extends StatefulWidget {
  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    UserDashboard(), // Replace with the actual page (e.g., UserDashboard)
    ChatPage(), // Chat Page
    CallPage(), // Call Page
    // Add other pages here if necessary
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Name"), // Title for your app
        centerTitle: true,
      ),
      body: _pages[_selectedIndex], // Show the page based on the selected index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: "Call"),
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
