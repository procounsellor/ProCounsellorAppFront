import 'package:flutter/material.dart';

class SavedArticlesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Articles"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: 6, // Example: Replace with actual saved article count
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.bookmark, color: Color(0xFFF0BB78)),
              title: Text("Saved Article ${index + 1}"),
              subtitle: Text("This is a saved article."),
              trailing: Icon(Icons.open_in_new, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opening Saved Article ${index + 1}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
