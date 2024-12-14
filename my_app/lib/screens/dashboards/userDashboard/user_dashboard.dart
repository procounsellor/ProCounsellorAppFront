import 'package:flutter/material.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'details_page.dart';
import 'call_page.dart'; // Import CallPage

class UserDashboard extends StatelessWidget {
  final VoidCallback onSignOut;
  final String username;

  UserDashboard({required this.onSignOut, required this.username});

  // Sample data for the three lists
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $username!"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 20), // Smaller sign-out button
            tooltip: "Sign Out",
            onPressed: onSignOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchPage(
                      list1: _list1,
                      list2: _list2,
                      list3: _list3,
                    ),
                  ),
                );
              },
              child: Text("Search"),
            ),
            SizedBox(height: 20),
            // Horizontal Lists
            Expanded(
              child: ListView(
                children: [
                  _buildHorizontalList("Live Counsellors", _list1),
                  SizedBox(height: 20),
                  _buildHorizontalList("Top Rated Counsellors", _list2),
                  SizedBox(height: 20),
                  _buildHorizontalList("Top News", _list3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 100, // Fixed height for the list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(itemName: items[index]),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 100, // Fixed width for each card
                    alignment: Alignment.center,
                    child: Text(
                      items[index],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
