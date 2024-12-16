import 'package:flutter/material.dart';

class LearnWithUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> learningTopics = [
      "Stress Management",
      "Time Management",
      "Mental Wellness",
      "Personal Growth",
      "Form Filling"
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Learn with Us"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: learningTopics.length,
        itemBuilder: (context, index) {
          final topic = learningTopics[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(topic, style: TextStyle(fontSize: 18.0)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Learn more about $topic")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
