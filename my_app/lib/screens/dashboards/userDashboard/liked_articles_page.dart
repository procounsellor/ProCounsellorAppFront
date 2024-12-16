import 'package:flutter/material.dart';

class LikedArticlesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liked Articles"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: 8, // Example: Replace with actual article data count
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.article, color: Color(0xFFF0BB78)),
              title: Text("Article ${index + 1}"),
              subtitle: Text("This is a liked article."),
              trailing: Icon(Icons.open_in_new, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opening Article ${index + 1}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
