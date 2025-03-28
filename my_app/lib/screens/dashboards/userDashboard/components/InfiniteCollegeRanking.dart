import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:my_app/screens/dashboards/userDashboard/headersText/TrendingHeader.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef MyBuilder = void Function(
    BuildContext context, void Function() methodFromChild);

class InfiniteCollegeRanking extends StatefulWidget {
  final MyBuilder builder;

  const InfiniteCollegeRanking({super.key, required this.builder});
  @override
  _InfiniteCollegeRanking1State createState() =>
      _InfiniteCollegeRanking1State();
}

class _InfiniteCollegeRanking1State extends State<InfiniteCollegeRanking> {
  List<Map<String, dynamic>> _collegeList = [];
  List<Map<String, dynamic>> _displayedColleges = [];
  int _loadedCount = 10; // Start with 10 items
  bool _isLoading = false;
  List<String> uniqueCategories = [];
  Map<String, List<Map<String, dynamic>>> categorizedColleges = {};
  ScrollController _scrollController = ScrollController();
  String unsplashApiKey =
      "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA"; // ✅ Set Unsplash API Key

  @override
  void initState() {
    super.initState();
    _loadColleges();
    _scrollController.addListener(_onScroll);
  }

  /// **Loads the JSON file from assets**
  Future<void> _loadColleges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_colleges");

    if (cachedData != null) {
      List<dynamic> jsonData = json.decode(cachedData);
      setState(() {
        _collegeList = jsonData.cast<Map<String, dynamic>>();

        uniqueCategories = _collegeList
            .map((college) => college['category'] as String)
            .toSet()
            .toList();

        _displayedColleges = _collegeList.take(_loadedCount).toList();
      });
    } else {
      try {
        String jsonString = await rootBundle
            .loadString('assets/data/updated_college_ranking.json');
        List<dynamic> jsonData = json.decode(jsonString);
        _collegeList = jsonData.cast<Map<String, dynamic>>();
        uniqueCategories = _collegeList
            .map((college) => college['category'] as String)
            .toSet()
            .toList();
        print(_collegeList);
        // process data
      } catch (e) {
        print("❌ Error loading JSON: $e");
      }

      // String jsonString =
      //     await rootBundle.loadString('data/updated_college_ranking.json');
      // List<dynamic> jsonData = json.decode(jsonString);
      // _collegeList = jsonData.cast<Map<String, dynamic>>();
      // print(_collegeList);
      // await _fetchUnsplashImages(); // ✅ Fetch Unsplash Images
    }
  }

  /// **Fetches Unsplash Images for Each College**
  Future<void> _fetchUnsplashImages() async {
    for (var college in _collegeList) {
      final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${college['category']}college&client_id=$unsplashApiKey"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        college["image"] = data["urls"]["small"];
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_colleges", json.encode(_collegeList));

    setState(() {
      _displayedColleges = _collegeList.take(_loadedCount).toList();
    });
  }

  /// **Handles Infinite Scrolling**
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      loadMoreColleges();
    }
  }

  /// **Loads More Colleges Dynamically**
  void loadMoreColleges() {
    // print(".......loading");
    if (_isLoading || _loadedCount >= _collegeList.length) return;

    setState(() => _isLoading = true);

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _loadedCount += 10; // Load 10 more items
        _displayedColleges = _collegeList.take(_loadedCount).toList();
        for (String category in uniqueCategories) {
          if (!categorizedColleges.containsKey(category)) {
            for (var college in _collegeList) {
              if (college['category'] == category) {
                // Initialize the category "Science" in the map if not present
                categorizedColleges.putIfAbsent(category, () => []);

                // Add the college only if the "Science" list has less than 10 items
                if (categorizedColleges[category]!.length < 10) {
                  categorizedColleges[category]!.add(college);
                }
              }
            }
            _isLoading = false;
            return;
          }
        }
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> ratings = [
    "3.9",
    "4.2",
    "4.0",
    "3.1",
    "3.0",
    "4.9",
    "2.1",
    "5.0",
    "3.4",
    "4.5",
  ];
  List<String> noOfRatings = [
    "2k",
    "400",
    "139k",
    "22",
    "1",
    "7",
    "88",
    "1",
    "77k",
    "12k",
  ];

  @override
  Widget build(BuildContext context) {
    widget.builder.call(context, () {
      loadMoreColleges();
    });
    return Column(children: [
      for (String key in categorizedColleges.keys)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (uniqueCategories.indexOf(key) != 0) Divider(),
          if (uniqueCategories.indexOf(key) != 0)
            SizedBox(
              height: 10,
            ),
          Text(
            key,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.grey[400],
            ),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (int i = 0; i < 2; i++)
              Expanded(
                  child: Column(
                children: [
                  for (int j = i; j < categorizedColleges[key]!.length; j += 2)
                    Container(
                      margin: EdgeInsets.only(
                          top: 2,
                          bottom: 2,
                          left: i == 1 ? 2 : 0,
                          right: i == 0 ? 2 : 0),
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        // borderRadius: BorderRadius.circular(12),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.grey.withOpacity(0.3),
                        //     spreadRadius: 2,
                        //     blurRadius: 6,
                        //     offset: Offset(0, 2),
                        //   ),
                        // ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image:
                                        AssetImage("assets/images/a$j.jpg"))),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ratings[j],
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.black54),
                                    ),
                                    Icon(
                                      Icons.star,
                                      color: Colors.black38,
                                      size: 10,
                                    ),
                                    Text(
                                      "|",
                                      style: TextStyle(
                                          fontSize: 8, color: Colors.black26),
                                    ),
                                    SizedBox(
                                      width: 2,
                                    ),
                                    Text(noOfRatings[j],
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54))
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            categorizedColleges[key]![j]["name"],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            categorizedColleges[key]![j]["category"],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          // Text(
                          //   categorizedColleges[key][j]["description"],
                          //   maxLines: 2,
                          //   overflow: TextOverflow.ellipsis,
                          //   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          // ),
                        ],
                      ),
                    ),
                ],

                // } else {
                //   return
                // if (_isLoading) Center(child: CircularProgressIndicator())
                // }
                // },
              ))
          ]),
        ]),
      if (_isLoading) Center(child: CircularProgressIndicator())
    ]);
    //   ),
    // );
  }
}
