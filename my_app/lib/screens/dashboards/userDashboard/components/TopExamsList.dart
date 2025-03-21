import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TopExamsList extends StatefulWidget {
  @override
  _TopExamsListState createState() => _TopExamsListState();
}

class _TopExamsListState extends State<TopExamsList> {
  final List<Map<String, String>> _topExams = [
    {"name": "JEE Advanced", "keyword": "exam education"},
    {"name": "NEET", "keyword": "medicine study"},
    {"name": "CAT", "keyword": "mba business"},
    {"name": "SAT", "keyword": "exam study"},
    {"name": "IELTS", "keyword": "english test"},
    {"name": "TOEFL", "keyword": "language learning"},
  ];

  List<Map<String, String>> _examImages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedExams();
  }

  /// **Loads Cached Data or Fetches New Data**
  Future<void> _loadCachedExams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_exam_images");

    if (cachedData != null) {
      try {
        List<dynamic> decodedData = json.decode(cachedData);
        setState(() {
          _examImages = decodedData.map<Map<String, String>>((item) {
            return {
              "name": item["name"].toString(),
              "image": item["image"].toString(),
            };
          }).toList();
        });
      } catch (e) {
        print("❌ Error parsing cached exams: $e");
        await _fetchExamImages(); // Fallback to API if cache is corrupted
      }
    } else {
      await _fetchExamImages();
    }
  }

  /// **Fetches Exam Images from Unsplash**
  Future<void> _fetchExamImages() async {
    List<Map<String, String>> fetchedExams = [];
    String unsplashApiKey =
        "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA"; // ✅ Hardcoded API Key

    for (var exam in _topExams) {
      final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${exam['keyword']}&client_id=$unsplashApiKey"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        fetchedExams.add({
          "name": exam["name"]!,
          "image": data["urls"]["small"],
        });
      } else {
        fetchedExams.add({
          "name": exam["name"]!,
          "image": "https://via.placeholder.com/100", // Default image
        });
      }
    }

    // ✅ Update State & Cache Data
    setState(() {
      _examImages = fetchedExams;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_exam_images", json.encode(fetchedExams));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Exams in India & Abroad",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  // ✅ Future implementation: Navigate to full exam list page
                  print("See More clicked!");
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18, // ✅ Small, non-intrusive size
                  color:
                      Colors.grey[700], // ✅ Subtle color to blend with design
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.6, // Dynamic height
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: _examImages.isNotEmpty
                  ? _examImages.length
                  : _topExams.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9, // Keeps image & text proportionate
              ),
              itemBuilder: (context, index) {
                final exam = _examImages.isNotEmpty
                    ? _examImages[index]
                    : _topExams[index];
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            0.20, // Dynamic width
                        height: MediaQuery.of(context).size.width *
                            0.20, // Dynamic height
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(exam["image"] ??
                                "https://via.placeholder.com/100"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      exam["name"]!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
