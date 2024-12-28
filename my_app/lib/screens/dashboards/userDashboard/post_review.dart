import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostUserReview extends StatefulWidget {
  final String userName;
  final String counsellorName;

  PostUserReview({required this.userName, required this.counsellorName});

  @override
  _PostUserReviewState createState() => _PostUserReviewState();
}

class _PostUserReviewState extends State<PostUserReview> {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  bool _isSubmitting = false;

  // Post review function
  Future<void> postReview() async {
    setState(() {
      _isSubmitting = true;
    });

    // Parse the rating as a float (double)
    final rating = double.tryParse(_ratingController.text) ?? 1.0; // Default to 1.0 if invalid

    // Prepare the body for the POST request
    final body = {
      'reviewText': _reviewController.text,
      'rating': rating.toString(), // Ensure rating is sent as a string
    };

    final headers = {
      'Content-Type': 'application/json', // Use JSON format
    };

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/reviews/${widget.userName}/${widget.counsellorName}'),
      headers: headers,
      body: jsonEncode(body), // Encode the body as JSON
    );

    if (response.statusCode == 200) {
      print("Review posted successfully!");
    } else {
      print("Failed to post review.");
    }

    setState(() {
      _isSubmitting = false;
    });

    // After posting, navigate back to the previous page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post Review for ${widget.counsellorName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Write your review:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: "Enter your review",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            Text(
              "Rating:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _ratingController,
              keyboardType: TextInputType.numberWithOptions(decimal: true), // Ensure it's a float input
              decoration: InputDecoration(
                hintText: "Enter rating (1.0 to 5.0)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isSubmitting
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: postReview,
                    child: Text("Post Review"),
                  ),
          ],
        ),
      ),
    );
  }
}
