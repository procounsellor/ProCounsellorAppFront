import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../userDashboard/news_class.dart';
import '../userDashboard/news_details_page.dart';

class AllNewsPage extends StatefulWidget {
  @override
  _AllNewsPageState createState() => _AllNewsPageState();
}

class _AllNewsPageState extends State<AllNewsPage> {
  List<News> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    const String apiUrl = 'http://localhost:8080/api/news';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> newsData = json.decode(response.body);
        setState(() {
          _newsList = newsData.map((newsItem) => News.fromJson(newsItem)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All News")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _newsList.isEmpty
              ? Center(child: Text("No news available"))
              : ListView.separated(
                  itemCount: _newsList.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final news = _newsList[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: news.imageUrl.isNotEmpty
                            ? Image.network(
                                news.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image, size: 80),
                              )
                            : Icon(Icons.image_not_supported, size: 80),
                      ),
                      title: Text(
                        news.description,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailsPage(news: _newsList[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

// Blank page to be redirected when clicking a news item
class BlankPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("News Details")),
      body: Center(
        child: Text(
          "This is a blank page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
