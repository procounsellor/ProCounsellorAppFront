import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboards/userDashboard/top_news_carousel.dart';

class NewsDetailsPage extends StatelessWidget {
  final News news;

  const NewsDetailsPage({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("News Details"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description Paragraph
              Text(
                news.description,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  news.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      "Failed to load image",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Full News Content
              Text(
                news.fullNews,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
