import 'package:flutter/material.dart';
import '../wellness_form_page.dart';
import '../headersText/TrendingHeader.dart';
import 'stressmanagement/stress_management_page.dart';

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
      body: Column(
        children: [
          TrendingHeader(title: "Explore Topics"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                itemCount: learningTopics.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 3 / 3.5,
                ),
                itemBuilder: (context, index) {
                  final topic = learningTopics[index];
                  final imagePath =
                      'assets/images/learnwithus/${topic.toLowerCase().replaceAll(' ', '_')}.png';

                  return GestureDetector(
                    onTap: () {
                      if (topic == "Stress Management") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StressManagementPage(),
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
                    child: Column(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            elevation: 3,
                            color: Colors.grey[100],
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          topic,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
