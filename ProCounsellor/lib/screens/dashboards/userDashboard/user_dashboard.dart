import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:indexed/indexed.dart';
import 'dart:convert';
import 'dart:async';
import 'components/TopEvents.dart';
import '../../../services/api_utils.dart';
import 'search_page.dart';
import 'details_page.dart';
import 'top_news_carousel.dart'; // Import the TopNewsCarousel class
import 'components/TopExamsList.dart';
import 'components/TrendingCoursesList.dart';
import 'components/TopColleges.dart';
import 'components/UpcomingDeadlinesTicker.dart';
import 'components/InfiniteCollegeRanking.dart';
import 'headersText/TrendingHeader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/StateTagSelector.dart';

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
  late void Function() myMethod;
  void _onScroll() {
    if (!mounted) return; // <-- Safe check
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      try {
        myMethod.call();
        print("call");
      } catch (e) {
        print("⚠️ Error calling myMethod: $e");
      }
    }
  }

  ScrollController _scrollController = ScrollController();

  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    _scrollController.dispose();
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
        Uri.parse(
            '${ApiUtils.baseUrl}/api/user/${widget.username}/counsellorsAccordingToInterestedCourse/all'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _topRatedCounsellors = data;
        });
      } else if (response.statusCode == 404) {
        print('No counsellors found for the user.');
      } else {
        print(
            'Failed to load counsellors. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching top-rated counsellors: $e');
    }
  }

  // void _listenToCounsellorStates() {
  //   final databaseReference = FirebaseDatabase.instance.ref('counsellorStates');
  //   databaseReference.onValue.listen((event) {
  //     final snapshotValue = event.snapshot.value;

  //     if (snapshotValue is Map<dynamic, dynamic>) {
  //       final states = Map<String, dynamic>.from(snapshotValue);
  //       // if (!mounted) return;
  //       setState(() {
  //         _liveCounsellors = _topRatedCounsellors.where((counsellor) {
  //           final counsellorId = counsellor['userName'];
  //           final state = states[counsellorId]?['state'];
  //           return state == 'online'; // Include only online counsellors
  //         }).toList();
  //       });
  //     } else {
  //       print("Unexpected data type for snapshot value: $snapshotValue");
  //     }
  //   });
  // }
  void _listenToCounsellorStates() {
    final databaseReference = FirebaseDatabase.instance.ref('counsellorStates');
    databaseReference.onValue.listen((event) {
      final snapshotValue = event.snapshot.value;

      if (snapshotValue is Map<dynamic, dynamic>) {
        final states = Map<String, dynamic>.from(snapshotValue);
        if (!mounted) return;

        setState(() {
          // ✅ Step 1: Filter actual online counsellors
          final onlineCounsellors = _topRatedCounsellors.where((counsellor) {
            final counsellorId = counsellor['userName'];
            final state = states[counsellorId]?['state'];
            return state == 'online';
          }).toList();

          // ✅ Step 2: Add "0000000000" counsellor manually to the beginning
          final proAiCounsellor = {
            'userName': '0000000000',
            'firstName': 'Pro AI',
            'photoUrl':
                'https://via.placeholder.com/150', // or your custom image
            'ratePerYear': 'Free',
          };

          _liveCounsellors = [proAiCounsellor, ...onlineCounsellors];
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
            '${ApiUtils.baseUrl}/api/user/${widget.username}/counsellorsAccordingToInterestedCourse/${state.toLowerCase()}'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List<dynamic>;
          if (!mounted) return;

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
        if (_animationController.status != AnimationStatus.dismissed) {
          _animationController.reverse(); // ✅ Corrected
        }
      } else {
        _activeStates.add(state);
        if (_animationController.status != AnimationStatus.completed) {
          _animationController.forward(); // ✅ Corrected
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
        if (!mounted) return;
        if (_isAnimationControllerDisposed) return;
        if (mounted) {
          setState(() {
            _currentSearchHintIndex =
                (_currentSearchHintIndex + 1) % _searchHints.length;
          });
          _animationController.reset();
        }
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
                              style: GoogleFonts.outfit(
                                  color: Colors.grey, fontSize: 16),
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
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            // State Tags
            StateTagSelector(
              stateCounsellors: _stateCounsellors,
              activeStates: _activeStates,
              onToggleState: _toggleState,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: _scrollController,
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
                              // offset: Offset(0, 2),
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
                                  style: GoogleFonts.outfit(
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
                  // if (_liveCounsellors.isNotEmpty)
                  //   SlideTransition(
                  //     position: _pageAnimation,
                  //     child: Container(
                  //       margin: EdgeInsets.only(bottom: 16),
                  //       padding: EdgeInsets.all(12),
                  //       decoration: BoxDecoration(
                  //         color: Colors.white,
                  //         borderRadius: BorderRadius.circular(10),
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: Colors.grey.withOpacity(0.3),
                  //             spreadRadius: 1,
                  //             blurRadius: 6,
                  //             //  offset: Offset(0, 2),
                  //           ),
                  //         ],
                  //       ),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text(
                  //             "Live Counsellors",
                  //             style: GoogleFonts.outfit(
                  //                 fontSize: 18, fontWeight: FontWeight.bold),
                  //           ),
                  //           SizedBox(height: 10),
                  //           _buildHorizontalList("", _liveCounsellors),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  Indexer(children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 120.0,
                        viewportFraction: 1,
                        autoPlay: true,
                        onPageChanged: (index, reason) {
                          if (!mounted) return;
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
                                        //  offset: Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(5)),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      width: MediaQuery.of(context).size.width -
                                          205,
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
                                          style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: 2,
                                        ),
                                        Text(
                                          "Ask Councellor",
                                          style: GoogleFonts.outfit(
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
                                                  BorderRadius.circular(10)),
                                          child: Text(
                                            "Chat Now",
                                            style:
                                                GoogleFonts.outfit(fontSize: 8),
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
                                          spacing: const EdgeInsets.all(4.0),
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
                            // offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          UpcomingDeadlinesTicker(),
                          SizedBox(height: 10),
                          Text(
                            "Top Rated Counsellors",
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          _buildHorizontalList("", _topRatedCounsellors),
                          SizedBox(height: 15),
                          // if (_liveCounsellors.isNotEmpty)
                          //   SlideTransition(
                          //     position: _pageAnimation,
                          //     child: Container(
                          //       margin: EdgeInsets.only(bottom: 16),
                          //       padding: EdgeInsets.all(12),
                          //       decoration: BoxDecoration(
                          //         color: Colors.white,
                          //         borderRadius: BorderRadius.circular(10),
                          //         boxShadow: [
                          //           BoxShadow(
                          //             color: Colors.grey.withOpacity(0.3),
                          //             spreadRadius: 1,
                          //             blurRadius: 6,
                          //             //  offset: Offset(0, 2),
                          //           ),
                          //         ],
                          //       ),
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: [
                          //           Text(
                          //             "Live Counsellors",
                          //             style: GoogleFonts.outfit(
                          //                 fontSize: 18,
                          //                 fontWeight: FontWeight.bold),
                          //           ),
                          //           SizedBox(height: 10),
                          //           _buildHorizontalList("", _liveCounsellors),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _pageAnimation,
                    child: Container(
                      margin:
                          EdgeInsets.only(bottom: 16), // Spacing between cards
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.grey.withOpacity(0.3), // Subtle shadow
                            spreadRadius: 1,
                            blurRadius: 6,
                            //offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrendingHeader(title: "Top News"),
                          TopNewsCarousel(),
                          SizedBox(height: 10),

                          TrendingHeader(title: "Top Events"),
                          EventCarousel(),
                          SizedBox(height: 10),

                          TrendingHeader(title: "Top Colleges"),
                          TopCollegesList(),
                          SizedBox(height: 10),

                          const TrendingHeader(title: "Trending Exams"),

                          TopExamsList(),
                          SizedBox(height: 10),
                          //TopFormsList() // Use the external carousel widget
                          TrendingHeader(title: "Trending Courses"),
                          const SizedBox(height: 10),
                          TrendingCoursesList(),
                          TrendingHeader(title: "Explore More"),

                          // ✅ Adjust based on JSON content
                          InfiniteCollegeRanking(
                            builder: (BuildContext context,
                                void Function() methodFromChild) {
                              myMethod = methodFromChild;
                            },
                          )
                        ],
                      ),
                    ),
                  ),
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
            style:
                GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (title.isNotEmpty) SizedBox(height: 10),
        SizedBox(
          height: 165, // Adjusted height for added content
          child: ListView.builder(
            key: ValueKey(items.length), // ✅ Ensures proper state tracking
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              if (isNews) {
                // ✅ Ensure items[index] is a String
                final String newsTitle = items[index].toString();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName: newsTitle,
                          userId: widget.username,
                          counsellorId: '',
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    key: ValueKey(newsTitle), // ✅ Unique key for each news item
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.newspaper,
                              size: 40,
                              color: Colors.orange), // ✅ const for optimization
                          const SizedBox(height: 8),
                          Text(
                            newsTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12), // ✅ const
                          ),
                        ],
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
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    key: ValueKey(counsellor[
                        'userName']), // ✅ Unique key for each counsellor
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color(0xFFFFCC80), // Light orange border
                                width: 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                counsellor['photoUrl'] ??
                                    'https://via.placeholder.com/150',
                              ),
                              radius: 31,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            counsellor['firstName'] ??
                                counsellor['userName'] ??
                                'Unknown',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            counsellor['ratePerYear'] != null
                                ? "\$${counsellor['ratePerYear']}/year"
                                : "Rate not available",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          // Button-like text for "Contact"
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.green
                                  .withOpacity(0.1), // Light green background
                              border: Border.all(color: Colors.green, width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              "Contact",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                        ],
                      ),
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
