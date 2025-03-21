import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CollegeCarousel extends StatefulWidget {
  const CollegeCarousel({Key? key}) : super(key: key);

  @override
  _CollegeCarouselState createState() => _CollegeCarouselState();
}

class _CollegeCarouselState extends State<CollegeCarousel> {
  List<Map<String, String>> colleges = [];
  bool isLoading = true;

  // ✅ Hardcoded Unsplash API Key (Replace with your own)
  final String unsplashAccessKey =
      "nyo0kWYlUFOZGmzcya9tVx2ZefwACQ38BdfKTl-XrRA";
  final String cacheKey = "college_carousel_cache"; // ✅ Cache key for storage

  @override
  void initState() {
    super.initState();
    fetchCollegeImages();
  }

  // ✅ Fetch College Images with Caching
  Future<void> fetchCollegeImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ Step 1: Check Cache First
    String? cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      print("✅ Loaded colleges from cache");
      try {
        List<dynamic> decodedList = json.decode(cachedData);
        setState(() {
          colleges = decodedList.map((item) {
            return {
              'name': item['name'].toString(),
              'imageUrl': item['imageUrl'].toString(),
            };
          }).toList();
          isLoading = false;
        });
        return;
      } catch (e) {
        print("❌ Error decoding cached data: $e");
      }
    }

    // ✅ Step 2: Fetch from API if cache is empty
    try {
      final response = await http.get(
        Uri.parse(
            "https://api.unsplash.com/search/photos?query=university&per_page=5&client_id=$unsplashAccessKey"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'];

        List<Map<String, String>> fetchedColleges = results.map((item) {
          return {
            'name': item['alt_description']?.toString() ?? 'Top University',
            'imageUrl': item['urls']['regular']?.toString() ?? '',
          };
        }).toList();

        // ✅ Step 3: Store Data in Cache
        await prefs.setString(cacheKey, json.encode(fetchedColleges));

        // ✅ Step 4: Update UI
        setState(() {
          colleges = fetchedColleges;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch images");
      }
    } catch (e) {
      print("Error fetching images: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Text(
        //   "Top Colleges",
        //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        // ),
        SizedBox(height: 10),

        // ✅ Show Loading Indicator while fetching data
        isLoading
            ? CircularProgressIndicator()
            : CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  enableInfiniteScroll: true,
                ),
                items: colleges.map((college) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(college['imageUrl']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                college['name']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ],
    );
  }
}
