import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'call_page.dart';
import 'chat_page.dart';
import 'details_page.dart';
import 'search_page.dart'; // Import SearchPage

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
  final List<String> _list1 = [
    "Apple",
    "Banana",
    "Cherry",
    "Date",
    "Elderberry"
  ];
  final List<String> _list2 = ["Fish", "Goat", "Horse", "Iguana", "Jaguar"];
  final List<String> _list3 = ["Kite", "Lion", "Monkey", "Nest", "Owl"];

  @override
  void initState() {
    super.initState();

    // Initialize the pages with dynamic data
    _pages.add(UserDashboard(
        onSignOut: widget.onSignOut,
        username: widget.username)); // User Dashboard
    _pages.add(ChatPage(liveCounsellors: [
      "Apple",
      "Banana",
      "Cherry",
      "Date",
      "Elderberry"
    ], topRatedCounsellors: [
      "Fish",
      "Goat",
      "Horse",
      "Iguana",
      "Jaguar"
    ])); // Chat Page
    _pages.add(CallPage(liveCounsellors: [
      "Fish",
      "Goat",
      "Horse",
      "Iguana",
      "Jaguar"
    ], topRatedCounsellors: [
      "Fish",
      "Goat",
      "Horse",
      "Iguana",
      "Jaguar"
    ])); // Call Page
    _pages.add(SearchPage(
        list1: ["Fish", "Goat", "Horse", "Iguana", "Jaguar"],
        list2: ["Fish", "Goat", "Horse", "Iguana", "Jaguar"],
        list3: ["Fish", "Goat", "Horse", "Iguana", "Jaguar"])); // Search Page
    _pages.add(DetailsPage(itemName: 'Item')); // Details Page
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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: "Call"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
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
