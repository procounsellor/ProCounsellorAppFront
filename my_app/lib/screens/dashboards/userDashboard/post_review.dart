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
  String? counsellorPhotoUrl;
  String? counsellorFullName;

  @override
  void initState() {
    super.initState();
    fetchCounsellorDetails();
  }

  Future<void> fetchCounsellorDetails() async {
    final response = await http.get(
      Uri.parse(
          'http://localhost:8080/api/counsellor/${widget.counsellorName}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        counsellorPhotoUrl = data['photoUrl'];
        counsellorFullName = data['firstName'];
      });
    } else {
      print('Failed to load counsellor details');
    }
  }

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
      Uri.parse(
          'http://localhost:8080/api/reviews/${widget.userName}/${widget.counsellorName}'),
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

// Updated buildCounsellorCard for half-width image with name and prompt on the right
  Widget buildCounsellorCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: counsellorPhotoUrl != null
                  ? Image.network(
                      counsellorPhotoUrl!,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/placeholder.png',
                      height: 250,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                counsellorFullName ?? 'Counsellor',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 6),
              Text(
                "would like to know about your experience. You can tell us how he helped you or if needs to be better.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Post Review', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCounsellorCard(),
            SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: "Share your experience...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 24),
            Text("Rate your experience",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            buildStarRating(),
            SizedBox(height: 10),
            Center(
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: postReview,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Submit Review",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
