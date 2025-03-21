import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpcomingDeadlinesTicker extends StatefulWidget {
  @override
  _UpcomingDeadlinesTickerState createState() =>
      _UpcomingDeadlinesTickerState();
}

class _UpcomingDeadlinesTickerState extends State<UpcomingDeadlinesTicker> {
  final List<Map<String, String>> _deadlines = [
    {"title": "JEE Advanced Registration", "date": "April 15, 2025"},
    {"title": "NEET Application Deadline", "date": "March 20, 2025"},
    {"title": "CAT Exam Last Date", "date": "November 10, 2025"},
    {"title": "SAT Registration Closes", "date": "August 5, 2025"},
    {"title": "IELTS Exam Booking", "date": "June 25, 2025"},
  ];

  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadCachedDeadlines();
    _startTicker();
  }

  /// **Starts Auto-Updating Ticker**
  void _startTicker() {
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _deadlines.length;
      });
    });
  }

  /// **Loads Cached Deadlines (If Available)**
  Future<void> _loadCachedDeadlines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString("cached_deadlines");

    if (cachedData != null) {
      try {
        List<dynamic> decodedData = json.decode(cachedData);
        setState(() {
          _deadlines.clear();
          _deadlines.addAll(decodedData.map<Map<String, String>>((item) {
            return {
              "title": item["title"].toString(),
              "date": item["date"].toString()
            };
          }).toList());
        });
      } catch (e) {
        print("❌ Error parsing cached deadlines: $e");
      }
    }
  }

  /// **Disposes Timer When Widget is Removed**
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: Text(
                "${_deadlines[_currentIndex]['title']} - ${_deadlines[_currentIndex]['date']}",
                key: ValueKey<String>(_deadlines[_currentIndex]['title']!),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
