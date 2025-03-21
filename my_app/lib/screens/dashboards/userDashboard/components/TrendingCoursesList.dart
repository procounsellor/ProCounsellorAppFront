import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TrendingCoursesList extends StatefulWidget {
  @override
  _TrendingCoursesListState createState() => _TrendingCoursesListState();
}

class _TrendingCoursesListState extends State<TrendingCoursesList> {
  final List<Map<String, String>> _trendingCourses = [
    {"name": "Full Stack Web Development", "keyword": "web coding"},
    {"name": "Data Science & AI", "keyword": "data analysis"},
    {"name": "Cyber Security", "keyword": "cyber security"},
    {"name": "UI/UX Design", "keyword": "design creativity"},
    {"name": "Cloud Computing", "keyword": "cloud technology"},
    {"name": "Digital Marketing", "keyword": "marketing online"},
  ];

  List<Map<String, String>> _courseImages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedCourses();
  }

  /// **Loads Cached Data or Fetches New Data**
  Future<void> _loadCachedCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_course_images");

    if (cachedData != null) {
      try {
        List<dynamic> decodedData = json.decode(cachedData);
        setState(() {
          _courseImages = decodedData.map<Map<String, String>>((item) {
            return {
              "name": item["name"].toString(),
              "image": item["image"].toString(),
            };
          }).toList();
        });
      } catch (e) {
        print("❌ Error parsing cached courses: $e");
        await _fetchCourseImages();
      }
    } else {
      await _fetchCourseImages();
    }
  }

  /// **Fetches Course Images from Unsplash**
  Future<void> _fetchCourseImages() async {
    List<Map<String, String>> fetchedCourses = [];
    String unsplashApiKey =
        "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA"; // ✅ Hardcoded API Key

    for (var course in _trendingCourses) {
      final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${course['keyword']}&client_id=$unsplashApiKey"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        fetchedCourses.add({
          "name": course["name"]!,
          "image": data["urls"]["small"],
        });
      } else {
        fetchedCourses.add({
          "name": course["name"]!,
          "image": "https://via.placeholder.com/100",
        });
      }
    }

    // ✅ Update State & Cache Data
    setState(() {
      _courseImages = fetchedCourses;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_course_images", json.encode(fetchedCourses));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header with "See More" icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   "Trending Courses",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // ),
              GestureDetector(
                onTap: () {
                  print("See More clicked! Future navigation here.");
                },
                child: Icon(
                  Icons.double_arrow_rounded,
                  size: 36,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // 🔹 Grid Layout with Smaller Icons
          SizedBox(
            height: (MediaQuery.of(context).size.width * 0.20 + 40) *
                2, // Dynamically adjust height
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: _courseImages.isNotEmpty
                  ? _courseImages.length
                  : _trendingCourses.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // ✅ 3 per row for better visual balance
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8, // ✅ Keeps images square
              ),
              itemBuilder: (context, index) {
                final course = _courseImages.isNotEmpty
                    ? _courseImages[index]
                    : _trendingCourses[index];
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            0.20, // ✅ Adjusted width
                        height: MediaQuery.of(context).size.width *
                            0.20, // ✅ Adjusted height
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(course["image"] ??
                                "https://via.placeholder.com/100"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      course["name"]!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
