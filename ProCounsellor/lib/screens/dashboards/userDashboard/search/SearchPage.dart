import 'dart:async';
import 'dart:convert';

import 'package:ProCounsellor/screens/dashboards/userDashboard/Friends/user_details_page.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/components/CollegeDetailsPage.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/components/Courses/CourseDetailsPage.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/components/ExamDetailsPage.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/services/api_utils.dart';
import '../components/EventDetailsPage.dart';
import '../model/events.dart';

class SearchPage extends StatefulWidget {
  final String userId;
  final Future<void> Function() onSignOut;

  const SearchPage({
    super.key,
    required this.userId,
    required this.onSignOut,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _selectedTab = 0;
  List<dynamic> allUsers = [];
  List<dynamic> allCounsellors = [];
  List<dynamic> allColleges = [];
  List<dynamic> allEvents = [];
  List<dynamic> allCourses = [];

  List<String> tabs = [
    'All',
    'Counsellors',
    'Users',
    'Colleges',
    'Events',
    'Courses',
    'Exams'
  ];
  List<String> allResults = []; // Replace with actual data later
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final usersResponse =
        await http.get(Uri.parse('${ApiUtils.baseUrl}/api/user/all-users'));
    final counsellorsResponse = await http
        .get(Uri.parse('${ApiUtils.baseUrl}/api/counsellor/all-counsellors'));

    final collegesString = await rootBundle
        .loadString('assets/data/colleges/college_ranking.json');
    final eventsString =
        await rootBundle.loadString('assets/data/top_trending_events.json');
    final coursesString = await rootBundle
        .loadString('assets/data/courses/trending-courses.json');

    setState(() {
      allUsers = (json.decode(usersResponse.body) as List).where((user) {
        return user['userName'] != widget.userId;
      }).toList();
      allCounsellors = json.decode(counsellorsResponse.body);
      allColleges = json.decode(collegesString);
      allEvents = json.decode(eventsString);
      allCourses = (json.decode(coursesString) as List).map((course) {
        return {
          ...course,
          'type': 'course', // add this!
        };
      }).toList();
      isLoading = false;
    });
  }

  Widget _buildResultTile(dynamic item) {
    final title = item['name'] ??
        item['title'] ??
        (item['firstName'] != null && item['lastName'] != null
            ? '${item['firstName']} ${item['lastName']}'
            : null) ??
        item['examName'] ??
        item['eventTitle'] ??
        "Untitled";

    final subtitle = item.containsKey('photo')
        ? 'Student'
        : item.containsKey('photoUrl')
            ? 'Counsellor'
            : item['type'] ?? '';

    Widget leadingWidget = _getLeading(item);

    // 🔗 Get sublist if it's a counsellor or college
    final sublistWidgets = <Widget>[];

    if (item.containsKey('photoUrl')) {
      // Counsellor → Show colleges
      final linkedColleges = allColleges.where((college) {
        return (college['state']?.toLowerCase() ?? '') ==
            (item['stateOfCounsellor']?.toLowerCase() ?? '');
      }).toList();

      if (linkedColleges.isNotEmpty) {
        sublistWidgets.addAll([
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              "Colleges Expertise",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child:
                buildHorizontalSublist(items: linkedColleges, isCollege: true),
          ),
        ]);
      }
    }

    if (item.containsKey('name')) {
      // College → Show counsellors
      final linkedCounsellors = allCounsellors.where((counsellor) {
        return (counsellor['stateOfCounsellor']?.toLowerCase() ?? '') ==
            (item['state']?.toLowerCase() ?? '');
      }).toList();

      if (linkedCounsellors.isNotEmpty) {
        sublistWidgets.addAll([
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              "Counsellors You Can Connect",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: buildHorizontalSublist(
                items: linkedCounsellors, isCollege: false),
          ),
        ]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: leadingWidget,
          title: Text(title, style: GoogleFonts.outfit()),
          subtitle: Text(subtitle,
              style: GoogleFonts.outfit(color: Colors.grey.shade600)),
          onTap: () {
            if (item.containsKey('photo')) {
              // 👤 User
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailsPage(
                    userId: item['userName'], // or item['_id']
                    myUsername: widget.userId,
                    onSignOut:
                        widget.onSignOut, // Assuming current user's username
                  ),
                ),
              );
            } else if (item.containsKey('photoUrl')) {
              // 👨‍⚕️ Counsellor
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailsPage(
                    itemName: item['firstName'] ?? 'Counsellor',
                    userId: widget.userId,
                    counsellorId: item['userName'],
                    counsellor: item,
                    onSignOut: widget.onSignOut,
                  ),
                ),
              );
            } else if (item.containsKey('rank')) {
              // 🏫 College
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollegeDetailsPage(
                    collegeName: item['name'],
                    username: widget.userId,
                  ),
                ),
              );
            } else if (item.containsKey('examName')) {
              // 📘 Exam
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamDetailsPage(
                    examName: item['examName'],
                    category: item['category'] ?? 'Engineering',
                    username: widget.userId,
                  ),
                ),
              );
            } else if (item['type'] == 'course') {
              // 🎓 Course
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CourseDetailsPage(
                          courseName: item['name'] ?? 'Untitled Course',
                          courseData: Map<String, dynamic>.from(item),
                        )),
              );
            } else if (item.containsKey('organizer')) {
              // 🎉 Event
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsPage(event: Event.fromJson(item)),
                ),
              );
            }
          },
        ),
        ...sublistWidgets,
        const Divider(thickness: 0.6),
      ],
    );
  }

  Widget buildHorizontalSublist({
    required List<dynamic> items,
    required bool isCollege,
  }) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final title = isCollege
              ? item['name'] ?? 'Unnamed'
              : '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}';

          final leading = _getLeading(item);

          return GestureDetector(
            onTap: () {
              if (isCollege) {
                // 🏫 Navigate to CollegeDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollegeDetailsPage(
                      collegeName: item['name'] ?? '',
                      username: widget.userId,
                    ),
                  ),
                );
              } else {
                // 👨‍⚕️ Navigate to DetailsPage (counsellor)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsPage(
                      itemName: item['firstName'] ?? 'Counsellor',
                      userId: widget.userId,
                      counsellorId: item['userName'],
                      counsellor: item,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getLeading(dynamic item) {
    if (item.containsKey('photo') &&
        item['photo'] != null &&
        item['photo'] != "") {
      return _squareImage(item['photo']);
    } else if (item.containsKey('photoUrl') &&
        item['photoUrl'] != null &&
        item['photoUrl'] != "") {
      return _squareImage(item['photoUrl']);
    } else if (item.containsKey('examName')) {
      return _initialBox('EX');
    } else if (item.containsKey('eventTitle')) {
      return _initialBox('EV');
    } else if (item['type'] == 'course') {
      return _initialBox('CR');
    } else if (item.containsKey('rank')) {
      if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: DecorationImage(
              image: NetworkImage(item['imageUrl']),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: const DecorationImage(
              image: AssetImage(
                  'assets/images/homepage/trending_colleges/fallback.png'),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } else {
      return _initialBox('?');
    }
  }

  Widget _squareImage(String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  // Widget _buildResultTile(dynamic item) {
  //   final title = item['name'] ??
  //       item['title'] ??
  //       (item['firstName'] != null && item['lastName'] != null
  //           ? '${item['firstName']} ${item['lastName']}'
  //           : null) ??
  //       item['examName'] ??
  //       item['eventTitle'] ??
  //       "Untitled";

  //   final subtitle = item.containsKey('photo')
  //       ? 'Student'
  //       : item.containsKey('photoUrl')
  //           ? 'Counsellor'
  //           : item.containsKey('examName')
  //               ? 'Exam'
  //               : item.containsKey('eventTitle')
  //                   ? 'Event'
  //                   : item.containsKey('courseTitle') ||
  //                           item['type'] == 'course'
  //                       ? 'Course'
  //                       : item.containsKey('collegeName')
  //                           ? 'College'
  //                           : '';

  //   Widget leadingWidget;

  //   if (item.containsKey('photo') &&
  //       item['photo'] != null &&
  //       item['photo'] != "") {
  //     leadingWidget = Container(
  //       width: 40,
  //       height: 40,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(6),
  //         image: DecorationImage(
  //           image: NetworkImage(item['photo']),
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //     );
  //   } else if (item.containsKey('photoUrl') &&
  //       item['photoUrl'] != null &&
  //       item['photoUrl'] != "") {
  //     leadingWidget = Container(
  //       width: 40,
  //       height: 40,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(6),
  //         image: DecorationImage(
  //           image: NetworkImage(item['photoUrl']),
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //     );
  //   } else if (item.containsKey('name')) {
  //     leadingWidget = _initialBox('EX');
  //   } else if (item.containsKey('eventTitle')) {
  //     leadingWidget = _initialBox('EV');
  //   } else if (item.containsKey('salary_range') || item['type'] == 'course') {
  //     leadingWidget = _initialBox('CR');
  //   } else if (item.containsKey('state')) {
  //     leadingWidget = _initialBox('C');
  //   } else {
  //     leadingWidget = _initialBox('?');
  //   }

  //   return ListTile(
  //     leading: leadingWidget,
  //     title: Text(title, style: GoogleFonts.outfit()),
  //     subtitle: Text(subtitle,
  //         style: GoogleFonts.outfit(color: Colors.grey.shade600)),
  //     onTap: () {
  //       if (item.containsKey('photo')) {
  //         // 👤 User
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => UserDetailsPage(
  //               userId: item['userName'], // or item['_id']
  //               myUsername: widget.userId, // Assuming current user's username
  //             ),
  //           ),
  //         );
  //       } else if (item.containsKey('photoUrl')) {
  //         // 👨‍⚕️ Counsellor
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => DetailsPage(
  //               itemName: item['firstName'] ?? 'Counsellor',
  //               userId: widget.userId,
  //               counsellorId: item['userName'],
  //               counsellor: item,
  //               onSignOut: widget.onSignOut,
  //             ),
  //           ),
  //         );
  //       } else if (item.containsKey('rank')) {
  //         // 🏫 College
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => CollegeDetailsPage(
  //               collegeName: item['name'],
  //               username: widget.userId,
  //             ),
  //           ),
  //         );
  //       } else if (item.containsKey('examName')) {
  //         // 📘 Exam
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => ExamDetailsPage(
  //               examName: item['examName'],
  //               category: item['category'] ?? 'Engineering',
  //               username: widget.userId,
  //             ),
  //           ),
  //         );
  //       } else if (item['type'] == 'course') {
  //         // 🎓 Course
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (_) => CourseDetailsPage(
  //                     courseName: item['name'] ?? 'Untitled Course',
  //                     courseData: Map<String, dynamic>.from(item),
  //                   )),
  //         );
  //       } else if (item.containsKey('organizer')) {
  //         // 🎉 Event
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (_) => EventDetailsPage(event: Event.fromJson(item)),
  //           ),
  //         );
  //       }
  //     },
  //   );
  // }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<dynamic> _filteredResults() {
    if (_query.isEmpty) return [];

    List<dynamic> data = [];
    switch (_selectedTab) {
      case 0:
        data = [
          ...allUsers,
          ...allCounsellors,
          ...allColleges,
          ...allEvents,
          ...allCourses,
        ];
        break;
      case 1:
        data = allCounsellors;
        break;
      case 2:
        data = allUsers;
        break;
      case 3:
        data = allColleges;
        break;
      case 4:
        data = allEvents;
        break;
      case 5:
        data = allCourses;
        break;
    }

    return data.where((item) {
      final combined = item.toString().toLowerCase();
      return combined.contains(_query.toLowerCase());
    }).toList();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _query = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredResults();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search anything...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.orange.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final selected = _selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(
                        tabs[index],
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.green,
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) => setState(() => _selectedTab = index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.trim().isEmpty
                      ? Center(
                          child: Text(
                            "Start typing to search...",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                "No results found",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _buildResultTile(item);
                              },
                            ),
            )
          ],
        ),
      ),
    );
  }

  Widget _initialBox(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
