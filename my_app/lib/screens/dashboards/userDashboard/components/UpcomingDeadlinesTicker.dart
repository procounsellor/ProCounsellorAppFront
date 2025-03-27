import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpcomingDeadlinesTicker extends StatefulWidget {
  @override
  _UpcomingDeadlinesTickerState createState() =>
      _UpcomingDeadlinesTickerState();
}

class _UpcomingDeadlinesTickerState extends State<UpcomingDeadlinesTicker>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _deadlines = [
    {"title": "JEE Advanced Registration", "date": "April 15, 2025"},
    {"title": "NEET Application Deadline", "date": "March 20, 2025"},
    {"title": "CAT Exam Last Date", "date": "November 10, 2025"},
    {"title": "SAT Registration Closes", "date": "August 5, 2025"},
    {"title": "IELTS Exam Booking", "date": "June 25, 2025"},
  ];

  int _currentIndex = 0;
  bool _showFront = true;

  late Timer _timer;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    double start = 0, end = pi;

    _animation = Tween<double>(begin: start, end: end).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward ||
            status == AnimationStatus.reverse) {
          // After animation completes, update index
          Future.delayed(Duration(milliseconds: 350), () {
            if (!mounted) return;
            setState(() {
              _currentIndex = (_currentIndex + 1) % _deadlines.length;
            });
          });
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(seconds: 4), (_) {
        if (!_controller.isAnimating) {
          rotateClock
              ? _controller.forward(from: 0)
              : _controller.reverse(from: 1);
          rotateClock = !rotateClock;
        }
      });
    });
  }

  bool rotateClock = true;

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

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

  Widget _buildFace({
    required String imagePath,
    required String text,
    required bool textOnLeft,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      alignment: textOnLeft ? Alignment.centerLeft : Alignment.centerRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin:
                    textOnLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: textOnLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: [0.0, 0.65],
              ),
            ),
          ),
        ),
        Container(
          width: screenWidth * 0.6,
          height: 100,
          padding: EdgeInsets.symmetric(horizontal: 16),
          alignment: textOnLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(
            text,
            textAlign: textOnLeft ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black87,
                  offset: Offset(1, 1),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final frontIndex = _currentIndex % _deadlines.length;
    final backIndex = (_currentIndex) % _deadlines.length;

    final frontData = _deadlines[frontIndex];
    final backData = _deadlines[backIndex];

    return Center(
      child: SizedBox(
        height: 100,
        width: screenWidth,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final isFirstHalf = _animation.value <= pi / 2;
            final showFront = isFirstHalf;

            final rotationY = _animation.value;
            final isBack = rotationY > pi / 2;

            final face = showFront
                ? _buildFace(
                    imagePath: 'assets/images/deadline.png',
                    text: "${frontData['title']} • ${frontData['date']}",
                    textOnLeft: true,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateY(pi), // flip horizontally
                    child: _buildFace(
                      imagePath: 'assets/images/deadline2.png',
                      text: "${backData['title']} • ${backData['date']}",
                      textOnLeft: false,
                    ),
                  );

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotationY),
              child: face,
            );
          },
        ),
      ),
    );
  }
}
