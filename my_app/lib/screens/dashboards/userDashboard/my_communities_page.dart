import 'package:flutter/material.dart';

class MyCommunitiesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Communities"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: 5, // Example: Replace with actual community data count
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.groups, color: Color(0xFFF0BB78)),
              title: Text("Community ${index + 1}"),
              subtitle: Text("This is one of your communities."),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Navigating to Community ${index + 1}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
