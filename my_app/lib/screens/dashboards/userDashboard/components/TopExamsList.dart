import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ExamsPage.dart';
import 'ExamDetailsPage.dart';

// import 'package:material_symbols_icons/material_symbols_icons.dart';

class TopExamsList extends StatefulWidget {
  @override
  _TopExamsListState createState() => _TopExamsListState();
}

class _TopExamsListState extends State<TopExamsList> {
  final List<Map<String, String>> _topExams = [
    {
      "name": "JEE Advanced",
      "image": "assets/images/homepage/trending_exams/jee.png",
      "category": "Engineering"
    },
    {
      "name": "NEET UG",
      "image": "assets/images/homepage/trending_exams/neet.png",
      "category": "Medical"
    },
    {
      "name": "CAT",
      "image": "assets/images/homepage/trending_exams/cat.png",
      "category": "Management"
    },
    {
      "name": "SAT",
      "image": "assets/images/homepage/trending_exams/sat.png",
      "category": "Engineering"
    },
    {
      "name": "IELTS",
      "image": "assets/images/homepage/trending_exams/ielts.png",
      "category": "Engineering"
    },
    {
      "name": "TOEFL",
      "image": "assets/images/homepage/trending_exams/toefl.png",
      "category": "Engineering"
    },
  ];

  List<Map<String, String>> _examImages = [];

  @override
  void initState() {
    super.initState();
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   "Top Exams in India & Abroad",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // ),
              GestureDetector(
                onTap: () {
                  // ✅ Future implementation: Navigate to full exam list page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExamsPage()),
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
                final exam = _topExams[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamDetailsPage(
                          examName: exam['name']!,
                          category: exam['category']!
                              .toLowerCase(), // Ensure it's lowercase
                        ),
                      ),
                    );
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
                              image: AssetImage(exam["image"]!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        exam["name"]!,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
