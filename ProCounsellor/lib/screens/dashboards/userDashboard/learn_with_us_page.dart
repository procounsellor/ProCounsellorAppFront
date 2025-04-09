import 'package:flutter/material.dart';
import 'wellness_form_page.dart';

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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textAlign: TextAlign.center,
              "Explore Topics",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: learningTopics.length,
                itemBuilder: (context, index) {
                  final topic = learningTopics[index];
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      title: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.orange,
                      ),
                      onTap: () {
                        if (topic == "Stress Management" ||
                            topic == "Personal Growth" ||
                            topic == "Mental Wellness") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WellnessFormPage(topic: topic),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Learn more about $topic"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
