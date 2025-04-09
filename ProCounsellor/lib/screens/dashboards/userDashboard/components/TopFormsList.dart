import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TopFormsList extends StatefulWidget {
  @override
  _TopFormsListState createState() => _TopFormsListState();
}

class _TopFormsListState extends State<TopFormsList> {
  final List<Map<String, String>> _topForms = [
    {"name": "JEE", "keyword": "college form"},
    {"name": "NEET Registration", "keyword": "medical application"},
    {"name": "CAT Application", "keyword": "mba business form"},
    {"name": "SAT Registration", "keyword": "university admission"},
    {"name": "IELTS Test Form", "keyword": "english proficiency"},
    {"name": "TOEFL Enrollment", "keyword": "language test"},
  ];

  List<Map<String, String>> _formImages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedForms();
  }

  /// **Loads Cached Data or Fetches New Data**
  Future<void> _loadCachedForms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_form_images");

    if (cachedData != null) {
      try {
        List<dynamic> decodedData = json.decode(cachedData);
        setState(() {
          _formImages = decodedData.map<Map<String, String>>((item) {
            return {
              "name": item["name"].toString(),
              "image": item["image"].toString(),
            };
          }).toList();
        });
      } catch (e) {
        print("❌ Error parsing cached forms: $e");
        await _fetchFormImages(); // Fallback to API if cache is corrupted
      }
    } else {
      await _fetchFormImages();
    }
  }

  /// **Fetches Form Images from Unsplash**
  Future<void> _fetchFormImages() async {
    List<Map<String, String>> fetchedForms = [];
    String unsplashApiKey =
        "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA"; // ✅ Hardcoded API Key

    for (var form in _topForms) {
      final response = await http.get(Uri.parse(
          "https://api.unsplash.com/photos/random?query=${form['keyword']}&client_id=$unsplashApiKey"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        fetchedForms.add({
          "name": form["name"]!,
          "image": data["urls"]["small"],
        });
      } else {
        fetchedForms.add({
          "name": form["name"]!,
          "image": "https://via.placeholder.com/100", // Default image
        });
      }
    }

    // ✅ Update State & Cache Data
    setState(() {
      _formImages = fetchedForms;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_form_images", json.encode(fetchedForms));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ✅ More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // ✅ Subtle shadow
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Forms & Applications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  print("See More clicked! Future navigation here.");
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // 🔹 Grid Layout (2 per row for better balance)
          SizedBox(
            height: MediaQuery.of(context).size.width * 1.2, // ✅ Dynamic height
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: _formImages.isNotEmpty
                  ? _formImages.length
                  : _topForms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // ✅ 2 per row for better visual balance
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9, // ✅ Slightly taller aspect ratio
              ),
              itemBuilder: (context, index) {
                final form = _formImages.isNotEmpty
                    ? _formImages[index]
                    : _topForms[index];
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            0.35, // ✅ Adjusted width
                        height: MediaQuery.of(context).size.width *
                            0.35, // ✅ Adjusted height
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(form["image"] ??
                                "https://via.placeholder.com/100"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      form["name"]!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
