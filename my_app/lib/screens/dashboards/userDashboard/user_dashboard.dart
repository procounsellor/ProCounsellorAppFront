import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'search_page.dart';
import 'details_page.dart';

class UserDashboard extends StatefulWidget {
  final VoidCallback onSignOut;
  final String username;

  UserDashboard({required this.onSignOut, required this.username});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<dynamic> _liveCounsellors = [];
  List<dynamic> _topRatedCounsellors = [];
  final List<String> _topNews = ["Kite", "Lion", "Monkey", "Nest", "Owl"];

  @override
  void initState() {
    super.initState();
    _fetchCounsellors();
  }

  Future<void> _fetchCounsellors() async {
    try {
      final response = await http.get(
          Uri.parse('http://localhost:8080/api/counsellor/all-counsellors'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        setState(() {
          // Filter for online counsellors
          _liveCounsellors = data.where((c) => c['state'] == 'ONLINE').toList();

          // Filter for top-rated counsellors
          _topRatedCounsellors = data.where((c) {
            final rating = c['rating'];
            return rating != null && rating >= 4.0;
          }).toList();
        });
      } else {
        print(
            'Failed to load counsellors. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching counsellors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${widget.username}!"),
        centerTitle: true,
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
                      list1: _extractNames(_liveCounsellors),
                      list2: _extractNames(_topRatedCounsellors),
                      list3: _topNews,
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
                  _buildHorizontalList("Live Counsellors", _liveCounsellors),
                  SizedBox(height: 20),
                  _buildHorizontalList(
                      "Top Rated Counsellors", _topRatedCounsellors),
                  SizedBox(height: 20),
                  _buildHorizontalList("Top News", _topNews, isNews: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractNames(List<dynamic> counsellors) {
    return counsellors
        .map((c) => c['firstName'] ?? c['userName'] ?? 'Unknown')
        .toList()
        .cast<String>();
  }

  Widget _buildHorizontalList(String title, List<dynamic> items,
      {bool isNews = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 120, // Fixed height for the list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              if (isNews) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName: items[index],
                          userId: widget.username, // Pass the userId
                          counsellorId: '', // For news, no counsellorId
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      child: Text(
                        items[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              } else {
                final counsellor = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName:
                              counsellor['firstName'] ?? counsellor['userName'],
                          userId: widget.username, // Pass the userId
                          counsellorId:
                              counsellor['userName'] ?? '', // Pass counsellorId
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            counsellor['photoUrl'] ??
                                'https://via.placeholder.com/100',
                          ),
                          radius: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          counsellor['firstName'] ??
                              counsellor['userName'] ??
                              'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
