import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
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
  Map<String, List<dynamic>> _stateCounsellors = {
    'Karnataka': [],
    'Maharashtra': [],
    'Tamil Nadu': [],
  };
  List<String> _activeStates = [];
  final List<String> _topNews = ["Kite", "Lion", "Monkey", "Nest", "Owl"];
  bool isLoading = true;
  String userFullName = "";

  @override
  void initState() {
    super.initState();
    _fetchTopCounsellors();
    _listenToCounsellorStates();
    fetchUserFullName(widget.username);
    _fetchCounsellorsByState();
  }

  Future<void> _fetchTopCounsellors() async {
    try {
      final response = await http.get(
          Uri.parse('http://localhost:8080/api/counsellor/sorted-by-rating'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _topRatedCounsellors = data;
        });
      } else {
        print(
            'Failed to load counsellors. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching top-rated counsellors: $e');
    }
  }

  void _listenToCounsellorStates() {
    final databaseReference = FirebaseDatabase.instance.ref('counsellorStates');
    databaseReference.onValue.listen((event) {
      final snapshotValue = event.snapshot.value;

      if (snapshotValue is Map<dynamic, dynamic>) {
        final states = Map<String, dynamic>.from(snapshotValue);
        setState(() {
          _liveCounsellors = _topRatedCounsellors.where((counsellor) {
            final counsellorId = counsellor['userName'];
            final state = states[counsellorId]?['state'];
            return state == 'online'; // Include only online counsellors
          }).toList();
        });
      } else {
        print("Unexpected data type for snapshot value: $snapshotValue");
      }
    });
  }

  void fetchUserFullName(String userName) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/reviews/user/fullname/$userName'),
      );

      if (response.statusCode == 200) {
        setState(() {
          userFullName = response.body;
        });
      } else {
        print('Error fetching user full name: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchCounsellorsByState() async {
    final states = ['Karnataka', 'Maharashtra', 'Tamil Nadu'];

    for (String state in states) {
      try {
        final response = await http.get(Uri.parse(
            'http://localhost:8080/api/user/${widget.username}/counsellorsAccordingToInterestedCourse/${state.toLowerCase()}'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List<dynamic>;
          setState(() {
            _stateCounsellors[state] = data;
          });
        } else {
          print(
              'Failed to load counsellors for $state: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching counsellors for $state: $e');
      }
    }
  }

  void _toggleState(String state) {
    setState(() {
      if (_activeStates.contains(state)) {
        _activeStates.remove(state);
      } else {
        _activeStates.add(state);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $userFullName !"),
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
                      liveCounsellors: _liveCounsellors,
                      topRatedCounsellors: _topRatedCounsellors,
                      topNews: _topNews,
                      userId: widget.username,
                    ),
                  ),
                );
              },
              child: Text("Search"),
            ),
            SizedBox(height: 20),
            // Heading for State Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Which state are you looking for?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            // State Tags
            Wrap(
              spacing: 8.0,
              children: _stateCounsellors.keys.map((state) {
                final isActive = _activeStates.contains(state);
                return FilterChip(
                  label: Text(state),
                  selected: isActive,
                  onSelected: (_) => _toggleState(state),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Horizontal Lists
            Expanded(
              child: ListView(
                children: [
                  if (_activeStates.isNotEmpty)
                    ..._activeStates.map((state) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Top Counsellors in $state",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            _buildHorizontalList(
                              "",
                              _stateCounsellors[state] ?? [],
                            ),
                            SizedBox(height: 20),
                          ],
                        )),
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

  Widget _buildHorizontalList(String title, List<dynamic> items,
      {bool isNews = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (title.isNotEmpty) SizedBox(height: 10),
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
                          userId: widget.username,
                          counsellorId: '',
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
                          userId: widget.username,
                          counsellorId: counsellor['userName'] ?? '',
                          isNews: false,
                          counsellor: counsellor,
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
                                'https://via.placeholder.com/150',
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
