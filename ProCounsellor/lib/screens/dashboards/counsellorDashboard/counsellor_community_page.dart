import 'package:flutter/material.dart';

class CounsellorCommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> communityGroups = [
      "Engineering",
      "MBA",
      "LAW",
      "Medical",
      "Other Allied Courses"
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Community"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: communityGroups.length,
        itemBuilder: (context, index) {
          final group = communityGroups[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(group, style: TextStyle(fontSize: 18.0)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opening $group")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
