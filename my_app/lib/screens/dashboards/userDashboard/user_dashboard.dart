import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:async';

import 'search_page.dart';
import 'details_page.dart';

class UserDashboard extends StatefulWidget {
  final VoidCallback onSignOut;
  final String username;

  UserDashboard({required this.onSignOut, required this.username});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with SingleTickerProviderStateMixin {
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

  List<String> _searchHints = [
    "Search colleges",
    "Search counsellors",
    "Search courses"
  ];
  int _currentSearchHintIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _fetchTopCounsellors();
    _listenToCounsellorStates();
    _fetchCounsellorsByState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300), // Faster transition
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -1),
    ).animate(_animationController);

    _startSearchHintCycle();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _startSearchHintCycle() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      _animationController.forward().then((_) {
        setState(() {
          _currentSearchHintIndex =
              (_currentSearchHintIndex + 1) % _searchHints.length;
        });
        _animationController.reset();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    onTap: () {
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
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFF3E0), // Light orange hue
                    ),
                    readOnly: true,
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: ClipRect(
                        child: SlideTransition(
                          position: _animation,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _searchHints[_currentSearchHintIndex],
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                return GestureDetector(
                  onTap: () => _toggleState(state),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange : Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      state,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
