import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'CollegeDetailsPage.dart';
import 'CollegesPage.dart';

class TopCollegesList extends StatefulWidget {
  @override
  _TopCollegesListState createState() => _TopCollegesListState();
}

class _TopCollegesListState extends State<TopCollegesList> {
  final List<Map<String, String>> _topColleges = [
    {
      "name": "Indian Institute of Technology Madras",
      "showName": "IIT Madras",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_madras.png",
    },
    {
      "name": "Indian Institute of Technology Bombay",
      "showName": "IIT Bombay",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_bombay.png",
    },
    {
      "name": "Indian Institute of Technology Delhi",
      "showName": "IIT Delhi",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_delhi.png",
    },
    {
      "name": "Indian Institute of Technology Kanpur",
      "showName": "IIT Kanpur",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_kanpur.png",
    },
    {
      "name": "Indian Institute of Technology Kharagpur",
      "showName": "IIT Kharagpur",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_kharagpur.png",
    },
    {
      "name": "Indian Institute of Technology Roorkee",
      "showName": "IIT Roorkee",
      "image":
          "assets/images/homepage/trending_colleges/indian_institute_of_technology_roorkee.png",
    },
  ];

  List<Map<String, String>> _collegeImages = [];

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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CollegesPage()),
                  );
                },
                child: Icon(
                  Icons.double_arrow_rounded,
                  size: 36,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: _collegeImages.isNotEmpty
                  ? _collegeImages.length
                  : _topColleges.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final college = _topColleges[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CollegeDetailsPage(collegeName: college["name"]!),
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
                          child: Image.asset(
                            college["image"]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/homepage/trending_colleges/fallback.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        college["showName"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
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
