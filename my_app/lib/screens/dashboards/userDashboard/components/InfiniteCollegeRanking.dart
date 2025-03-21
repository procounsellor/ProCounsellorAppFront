import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InfiniteCollegeRanking extends StatefulWidget {
  @override
  _InfiniteCollegeRankingState createState() => _InfiniteCollegeRankingState();
}

class _InfiniteCollegeRankingState extends State<InfiniteCollegeRanking> {
  List<Map<String, dynamic>> _collegeList = [];
  List<Map<String, dynamic>> _displayedColleges = [];
  int _loadedCount = 10; // Start with 10 items
  bool _isLoading = false;
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
        _displayedColleges = _collegeList.take(_loadedCount).toList();
      });
    } else {
      String jsonString = await rootBundle
          .loadString('assets/data/updated_college_ranking.json');
      List<dynamic> jsonData = json.decode(jsonString);
      _collegeList = jsonData.cast<Map<String, dynamic>>();
      //await _fetchUnsplashImages(); // ✅ Fetch Unsplash Images
    }
  }

  /// **Fetches Unsplash Images for Each College**
  Future<void> _fetchUnsplashImages() async {
    for (var college in _collegeList) {
      final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${college['category']} college&client_id=$unsplashApiKey"));

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
      _loadMoreColleges();
    }
  }

  /// **Loads More Colleges Dynamically**
  void _loadMoreColleges() {
    if (_isLoading || _loadedCount >= _collegeList.length) return;

    setState(() => _isLoading = true);

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _loadedCount += 10; // Load 10 more items
        _displayedColleges = _collegeList.take(_loadedCount).toList();
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _displayedColleges.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _displayedColleges.length) {
              final college = _displayedColleges[index];

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        college["image"],
                        height: 80,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            college["name"],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            college["category"],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            college["description"],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
