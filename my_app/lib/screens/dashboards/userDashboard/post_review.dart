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
  double _rating = 0.0;
  bool _isSubmitting = false;

  Future<void> postReview() async {
    setState(() {
      _isSubmitting = true;
    });

    final body = {
      'reviewText': _reviewController.text,
      'rating': _rating.toString(),
    };

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse('http://localhost:8080/api/reviews/${widget.userName}/${widget.counsellorName}'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("Review posted successfully!");
    } else {
      print("Failed to post review.");
    }

    setState(() {
      _isSubmitting = false;
    });

    Navigator.pop(context, true); // Pass true to indicate a refresh is needed
  }

  Widget buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: index < _rating ? Colors.orange : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Post Review"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Write your review:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: "Enter your review",
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[500]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rating:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    buildStarRating(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            _isSubmitting
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom( 
                                  backgroundColor: Colors.green[300],
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                    onPressed: postReview,
                    child: Text(
                      "Post Review",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
