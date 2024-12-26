import 'package:flutter/material.dart';

class AllReviewsPage extends StatelessWidget {
  final List<dynamic> reviews;

  AllReviewsPage({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Reviews"),
      ),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(review['userName'] ?? "Anonymous"),
              subtitle: Text(review['reviewText'] ?? ""),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  Text("${review['rating'] ?? 0}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
