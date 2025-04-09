import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../services/api_utils.dart';

class MyReviewPage extends StatefulWidget {
  final String username;

  const MyReviewPage({required this.username, Key? key}) : super(key: key);

  @override
  _MyReviewPageState createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<MyReviewPage> {
  List<dynamic> userReviews = [];
  bool isLoading = true;
  Map<String, bool> showComments = {};

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiUtils.baseUrl}/api/reviews/counsellor/${widget.username}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          userReviews = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addLike(String reviewId, List<String> userIDliked) async {
    try {
      bool isLiked = userIDliked.contains(widget.username);
      final response = isLiked
          ? await http.post(
              Uri.parse(
                  '${ApiUtils.baseUrl}/api/reviews/${widget.username}/$reviewId/unlike'),
            )
          : await http.post(
              Uri.parse(
                  '${ApiUtils.baseUrl}/api/reviews/${widget.username}/$reviewId/like'),
            );
      if (response.statusCode == 200) {
        fetchReviews();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> addComment(String reviewId, String commentText) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiUtils.baseUrl}/api/reviews/$reviewId/comments/${widget.username}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'commentText': commentText}),
      );
      if (response.statusCode == 200) {
        fetchReviews();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildUserReviews(List<dynamic> reviews) {
    return Column(
      children: reviews.map((review) {
        final reviewId = review['reviewId'];
        final userIDliked = List<String>.from(review['userIdsLiked'] ?? []);
        TextEditingController _commentController = TextEditingController();

        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(review["userPhotoUrl"] ??
                          "https://via.placeholder.com/150"),
                      radius: 30,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review["userFullName"] ?? "Unknown",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: List.generate(
                                5,
                                (index) => Icon(
                                      index < review['rating']
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.orange,
                                    )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  review['reviewText'] ?? "No review available",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 5),
                Text(
                  formatTimestamp(review['timestamp']['seconds']),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            userIDliked.contains(widget.username)
                                ? Icons.thumb_up
                                : Icons.thumb_up_off_alt,
                            color: userIDliked.contains(widget.username)
                                ? Colors.blueAccent
                                : Colors.black,
                          ),
                          onPressed: () => addLike(reviewId, userIDliked),
                        ),
                        Text("${review['noOfLikes']} Likes"),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showComments[reviewId] =
                              !(showComments[reviewId] ?? false);
                        });
                      },
                      child: Text(showComments[reviewId] == true
                          ? "Hide Comments"
                          : "View Comments"),
                    ),
                  ],
                ),
                if (showComments[reviewId] == true) ...[
                  Column(
                    children: review['comments']?.map<Widget>((comment) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  comment['photoUrl'] ??
                                      "https://via.placeholder.com/150"),
                            ),
                            title: Text(comment['userFullName'] ?? "Anonymous"),
                            subtitle: Text(comment['commentText'] ?? ""),
                          );
                        })?.toList() ??
                        [Text("No comments available.")],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            addComment(reviewId, _commentController.text);
                            _commentController.clear();
                          }
                        },
                      ),
                    ],
                  )
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Reviews"),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: _buildUserReviews(userReviews),
            ),
    );
  }
}
