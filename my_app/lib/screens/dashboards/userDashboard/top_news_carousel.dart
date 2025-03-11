import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/dashboards/userDashboard/news_class.dart';
import 'dart:convert';

import 'package:my_app/screens/dashboards/userDashboard/news_details_page.dart';

import '../../../services/api_utils.dart';

class TopNewsCarousel extends StatefulWidget {
  @override
  _TopNewsCarouselState createState() => _TopNewsCarouselState();
}

class _TopNewsCarouselState extends State<TopNewsCarousel> {
  final PageController _pageController = PageController();
  late Timer _timer;
  final List<News> _newsList = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    const String apiUrl = '${ApiUtils.baseUrl}/api/news';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> newsData = json.decode(response.body);
        for (var newsItem in newsData) {
          final news = News.fromJson(newsItem);
          setState(() {
            _newsList.add(news);
          });
        }
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_newsList.isNotEmpty) {
        setState(() {
          _currentPage = (_currentPage + 1) % _newsList.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _newsList.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _newsList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to News Details Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailsPage(news: _newsList[index]),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Image Section
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: Image.network(
                            _newsList[index].imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                "Failed to load image",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Description Section
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            _newsList[index].description,
                            style: TextStyle(fontSize: 14, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
