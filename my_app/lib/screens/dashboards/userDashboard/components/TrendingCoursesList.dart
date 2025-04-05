import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Courses/CoursesPage.dart';
import 'Courses/CourseDetailsPage.dart';
import 'package:flutter/services.dart';

class TrendingCoursesList extends StatefulWidget {
  @override
  _TrendingCoursesListState createState() => _TrendingCoursesListState();
}

class _TrendingCoursesListState extends State<TrendingCoursesList> {
  List<Map<String, String>> _trendingCourses = [];
  List<Map<String, String>> _courseImages = [];

  @override
  void initState() {
    super.initState();
    _loadTrendingCourses();
  }

  Future<void> _loadTrendingCourses() async {
    try {
      final String response = await rootBundle
          .loadString('assets/data/courses/trending-courses.json');
      final List<dynamic> data = json.decode(response);

      if (mounted) {
        setState(() {
          _trendingCourses = data.take(6).map<Map<String, String>>((item) {
            return {
              "name": item["name"].toString(),
              "category": item["category"].toString(),
              "description": item["description"].toString(),
            };
          }).toList();
        });
      }

      await _loadCachedCourses();
    } catch (e) {
      print("❌ Error loading trending courses JSON: $e");
    }
  }

  Future<void> _loadCachedCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_course_images");
    //String? cachedData = null;
    if (cachedData != null) {
      try {
        List<dynamic> decodedData = json.decode(cachedData);
        if (mounted) {
          setState(() {
            _courseImages = decodedData.map<Map<String, String>>((item) {
              return {
                "name": item["name"].toString(),
                "image": item["image"].toString(),
              };
            }).toList();
          });
        }
      } catch (e) {
        print("❌ Error parsing cached courses: $e");
        await _fetchCourseImages();
      }
    } else {
      await _fetchCourseImages();
    }
  }

  Future<void> _fetchCourseImages() async {
    List<Map<String, String>> fetchedCourses = [];
    String unsplashApiKey = "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA";

    for (var course in _trendingCourses) {
      try {
        final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${Uri.encodeComponent(course['name']!)}&client_id=$unsplashApiKey",
        ));

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
      } catch (e) {
        fetchedCourses.add({
          "name": course["name"]!,
          "image": "https://via.placeholder.com/100",
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _courseImages = fetchedCourses;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_course_images", json.encode(fetchedCourses));
  }

  Future<Map<String, dynamic>> _loadCourseByName(String name) async {
    final String response = await rootBundle
        .loadString('assets/data/courses/trending-courses.json');
    final List<dynamic> data = json.decode(response);
    for (var item in data) {
      if (item["name"] == name) {
        return item;
      }
    }
    return {"name": name, "description": {}}; // fallback
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoursesPage()),
                  );
                },
                child: Icon(
                  Icons.apps,
                  size: 36,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: (MediaQuery.of(context).size.width * 0.20 + 40) * 2,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: _courseImages.isNotEmpty
                  ? _courseImages.length
                  : _trendingCourses.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final course = _courseImages.isNotEmpty
                    ? _courseImages[index]
                    : _trendingCourses[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      try {
                        final courseData =
                            await _loadCourseByName(course["name"]!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailsPage(
                              courseName: courseData["name"],
                              courseData: Map<String, dynamic>.from(
                                  courseData["description"] ?? {}),
                            ),
                          ),
                        );
                      } catch (e) {
                        print("❌ Error navigating to CourseDetailsPage: $e");
                      }
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.20,
                            height: MediaQuery.of(context).size.width * 0.20,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
