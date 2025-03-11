import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../services/api_utils.dart';

class MyReviewPage extends StatefulWidget {
  final String username;

  const MyReviewPage({Key? key, required this.username}) : super(key: key);

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

  Future<List<dynamic>> fetchUserReviews(String userName) async {
    final response = await http.get(
      Uri.parse('${ApiUtils.baseUrl}/api/reviews/user/$userName'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data is List) {
        return data;
      } else if (data['reviews'] is List) {
        return data['reviews'];
      } else {
        print('Error: "reviews" is not a list');
        return [];
      }
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<void> fetchReviews() async {
    try {
      List<dynamic> reviews = await fetchUserReviews(widget.username);
      setState(() {
        userReviews = reviews;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching reviews: $e');
    }
  }

  Future<void> addComment(
      String reviewId, String commentText, String username) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiUtils.baseUrl}/api/reviews/$reviewId/comments/$username'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'commentText': commentText}),
      );

      if (response.statusCode == 200) {
        fetchReviews();
      } else {
        print('Error posting comment: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> addLike(
      String userId, String reviewId, List<String> userIDliked) async {
    try {
      bool isLiked = userIDliked.contains(userId);

      final response = isLiked
          ? await http.post(Uri.parse(
              '${ApiUtils.baseUrl}/api/reviews/$userId/$reviewId/unlike'))
          : await http.post(Uri.parse(
              '${ApiUtils.baseUrl}/api/reviews/$userId/$reviewId/like'));

      if (response.statusCode == 200) {
        fetchReviews();
      } else {
        print('Error toggling like: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.hour}:${date.minute} ${date.day}/${date.month}/${date.year}";
  }

  Widget ReviewCard({
    required Map<String, dynamic> review,
    required String userId,
    required void Function(String reviewId, String comment, String userId)
        addComment,
    required void Function(
            String userId, String reviewId, List<String> userIDliked)
        addLike,
  }) {
    final reviewId = review['reviewId'];
    final userIDliked = List<String>.from(review['userIDliked'] ?? []);
    final _commentController = TextEditingController();

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      review["counsellorPhotoUrl"] ?? 'https://via.placeholder.com/150'),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  review["counsellorFullName"] ?? review["counsellorName"],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  formatTimestamp(review['timestamp']['seconds']),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              review["reviewText"] ?? "No review text provided.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 6),
            Row(
              children: List.generate(
                review["rating"] ?? 0,
                (index) => Icon(Icons.star, color: Colors.orange, size: 16),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        userIDliked.contains(userId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: userIDliked.contains(userId)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: () => addLike(userId, reviewId, userIDliked),
                    ),
                    Text("${review['noOfLikes']}")
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showComments[reviewId] =
                          !(showComments[reviewId] ?? false);
                    });
                  },
                  child: Text("Comments"),
                ),
              ],
            ),
            if (showComments[reviewId] == true) ...[
              ...review["comments"]?.map<Widget>((comment) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment['photoUrl'] != null
                            ? NetworkImage(comment['photoUrl'])
                            : null,
                        child: comment['photoUrl'] == null
                            ? Icon(Icons.person, size: 20)
                            : null,
                        radius: 15,
                      ),
                      title: Text(comment['userFullName'] ?? comment['userName']),
                      subtitle: Text(comment['commentText'] ?? ""),
                    );
                  })?.toList() ??
                  [
                    Text("No comments available."),
                  ],
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      addComment(reviewId, _commentController.text, userId);
                      _commentController.clear();
                    }
                  },
                  child: Text("Post Comment"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Reviews"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userReviews.isEmpty
              ? Center(child: Text("No reviews available."))
              : ListView(
                  padding: EdgeInsets.all(8.0),
                  children: userReviews.map((review) {
                    return ReviewCard(
                      review: review,
                      userId: widget.username,
                      addComment: addComment,
                      addLike: addLike,
                    );
                  }).toList(),
                ),
    );
  }
}
