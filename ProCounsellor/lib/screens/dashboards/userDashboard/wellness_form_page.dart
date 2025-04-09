import 'package:flutter/material.dart';

class WellnessFormPage extends StatelessWidget {
  final String topic;

  WellnessFormPage({required this.topic});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> questions = [
      {"question": "How often do you feel stressed?"},
      {"question": "Do you find it hard to focus?"},
      {"question": "How satisfied are you with your daily routine?"},
      {"question": "Do you get enough sleep daily?"},
      {"question": "How often do you engage in physical activity?"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orange),
        title: Text(
          topic,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Answer the following questions:",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.0, // Smaller heading
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            questions[index]["question"]!,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              hintText: "Type your answer here...",
                              hintStyle: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Your responses have been submitted!"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
