import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:indexed/indexed.dart';
import 'dart:convert';
import 'dart:async';

import 'search_page.dart';
import 'details_page.dart';
import 'top_news_carousel.dart'; // Import the TopNewsCarousel class

class UserDashboard extends StatefulWidget {
  final Future<void> Function() onSignOut;
  final String username;

  UserDashboard({required this.onSignOut, required this.username});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  bool _isAnimationControllerDisposed = false;
  List<dynamic> _liveCounsellors = [];
  List<dynamic> _topRatedCounsellors = [];
  Map<String, List<dynamic>> _stateCounsellors = {
    'Karnataka': [],
    'Maharashtra': [],
    'TamilNadu': [],
  };
  List<String> _activeStates = [];
  final List<String> _topNews = ["Kite", "Lion", "Monkey", "Nest", "Owl"];
  bool isLoading = true;
  int currentIndex = 0;

  List<String> _searchHints = [
    "Search colleges",
    "Search counsellors",
    "Search courses"
  ];
  int _currentSearchHintIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  late AnimationController _pageController;
  late Animation<Offset> _pageAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTopCounsellorsAccordingToInterest();
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

    _pageController = AnimationController(
      duration:
          Duration(milliseconds: 300), // Duration for the slide transition
      vsync: this,
    );

    _pageAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0.05),
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    ));

    _startSearchHintCycle();
  }

  @override
  void dispose() {
    _isAnimationControllerDisposed = true;
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  var carouselItems = [
    ["assets/images/c1.png", "Don't worry about your\nfuture we're here"],
    ["assets/images/u1.png", "Which career option\nshould I choose?"],
  ];

  Future<void> _fetchTopCounsellorsAccordingToInterest() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/user/${widget.username}/counsellorsAccordingToInterestedCourse/all'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _topRatedCounsellors = data; // Map to your model if needed
        });
      } else if (response.statusCode == 404) {
        print('No counsellors found for the user.');
      } else {
        print('Failed to load counsellors. Status code: ${response.statusCode}');
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
    final states = ['Karnataka', 'Maharashtra', 'TamilNadu'];

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
  //if (!mounted || _pageController.isAnimating || _pageController.isCompleted) return;
  setState(() {
    if (_activeStates.contains(state)) {
      _activeStates.remove(state);
      if (_pageController.status != AnimationStatus.dismissed) {
        _pageController.reverse(); // Transition back to original position
      }
    } else {
      _activeStates.add(state);
      if (_pageController.status != AnimationStatus.completed) {
        _pageController.forward(); // Move lists down with transition
      }
    }
  });
}

void _startSearchHintCycle() {
  Timer.periodic(Duration(seconds: 3), (timer) {
    if (_isAnimationControllerDisposed || !mounted) {
      timer.cancel();
      return;
    }

    _animationController.forward().then((_) {
      if (!mounted || _isAnimationControllerDisposed) return;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                            onSignOut: widget.onSignOut,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stateCounsellors.keys.map((state) {
                  final isActive = _activeStates.contains(state);
                  return GestureDetector(
                    onTap: () => _toggleState(state),
                    child: Container(
                      margin: EdgeInsets.only(right: 8.0), // Space between tags
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: !isActive
                            ? Color(0xffeeeeee)
                            : Colors.orange[100], // Transparent background
                        // border: Border.all(
                        //   color: isActive
                        //       ? Colors.orange
                        //       : Color(
                        //           0xFFFFA726), // Active and inactive border colors
                        //   width: 2, // Border width
                        // ),
                        borderRadius:
                            BorderRadius.circular(5), // Rounded border
                      ),
                      child: Text(
                        state,
                        style: TextStyle(
                          // color: isActive
                          //     ? Colors.orange
                          //     : Colors
                          //         .black, // Text color for active/inactive state
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeStates.isNotEmpty)
                        SlideTransition(
                          position: _pageAnimation,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _activeStates.map((state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Top Counsellors in $state",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    _buildHorizontalList(
                                        "", _stateCounsellors[state] ?? []),
                                    SizedBox(height: 10)
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      if (_liveCounsellors.isNotEmpty)
                        SlideTransition(
                          position: _pageAnimation,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Live Counsellors",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                _buildHorizontalList("", _liveCounsellors),
                              ],
                            ),
                          ),
                        ),
                      Indexer(children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 120.0,
                            viewportFraction: 1,
                            autoPlay: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                          ),
                          items: carouselItems.map((i) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 100,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 5.0, vertical: 10),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          i[0],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              i[1],
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 2,
                                            ),
                                            Text(
                                              "Ask Councellor",
                                              style: TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withOpacity(0.4),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text(
                                                "Chat Now",
                                                style: TextStyle(fontSize: 8),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            )
                                          ],
                                        )
                                      ],
                                    ));
                              },
                            );
                          }).toList(),
                        ),
                        Indexed(
                          index: 3,
                          child: Positioned(
                              bottom: 8,
                              child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Center(
                                      child: DotsIndicator(
                                          dotsCount: carouselItems.length,
                                          position: currentIndex,
                                          decorator: DotsDecorator(
                                              size: const Size.square(5.0),
                                              spacing:
                                                  const EdgeInsets.all(4.0),
                                              activeSize:
                                                  const Size.square(5.0)))))),
                        ),
                      ]),
                      SlideTransition(
                        position: _pageAnimation,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Top Rated Counsellors",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              _buildHorizontalList("", _topRatedCounsellors),
                            ],
                          ),
                        ),
                      ),
                      SlideTransition(
                        position: _pageAnimation,
                        child: Container(
                          margin: EdgeInsets.only(
                              bottom: 16), // Spacing between cards
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey
                                    .withOpacity(0.3), // Subtle shadow
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Top News",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TopNewsCarousel(), // Use the external carousel widget
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          height: 160, // Adjusted height for added content
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
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 110, // Adjusted for rectangular dimensions
                    margin:
                        EdgeInsets.symmetric(horizontal: 4), // Reduced spacing
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 0), // Uniform shadow
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper, size: 40, color: Colors.orange),
                        SizedBox(height: 8),
                        Text(
                          items[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
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
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 110, // Adjusted for rectangular dimensions
                    margin:
                        EdgeInsets.symmetric(horizontal: 4), // Reduced spacing
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 0), // Uniform shadow
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Color(0xFFFFCC80), // Thin light orange border
                              width: 1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              counsellor['photoUrl'] ??
                                  'https://via.placeholder.com/150',
                            ),
                            radius: 31, // Increased radius
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          counsellor['firstName'] ??
                              counsellor['userName'] ??
                              'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          counsellor['ratePerYear'] != null
                              ? "\$${counsellor['ratePerYear']}/year"
                              : "Rate not available",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 6),
                        // Button-like text for "Contact"
                        Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green
                                .withOpacity(0.1), // Light green background
                            border: Border.all(
                              color: Colors.green, // Green border
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "Contact",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
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
