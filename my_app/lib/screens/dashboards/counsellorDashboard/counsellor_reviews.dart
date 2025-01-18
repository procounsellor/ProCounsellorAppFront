import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyReviewPage extends StatefulWidget {
  final String username;

  const  MyReviewPage({required this.username, Key? key}) : super(key: key);

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
      Uri.parse('http://localhost:8080/api/reviews/counsellor/$userName'),
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

  Future<String> fetchCounsellorFullName(String counsellorName) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/reviews/counsellor/fullname/$counsellorName'),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Error fetching counsellor full name: ${response.body}');
        return "Unknown";
      }
    } catch (e) {
      print('Error: $e');
      return "Unknown";
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

  Future<void> addComment(String reviewId, String commentText, String username) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/reviews/$reviewId/comments/$username'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'commentText': commentText}),
      );

      if (response.statusCode == 200) {
        fetchReviews(); // Refresh reviews after adding the comment
      } else {
        print('Error posting comment: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

Future<void> addLike(String userId, String reviewId, List<String> userIDliked) async {
  try {
    final String userId = widget.username; // Assuming userId is the username (you can change this based on your logic)

    // Check if the current user has already liked the review
    bool isLiked = userIDliked.contains(userId);

    final response = isLiked
        ? await http.post(
            Uri.parse('http://localhost:8080/api/reviews/$userId/$reviewId/unlike'),
          ) // Unliking
        : await http.post(
            Uri.parse('http://localhost:8080/api/reviews/$userId/$reviewId/like'),
          ); // Liking

    if (response.statusCode == 200) {
      fetchReviews(); // Refresh reviews after toggling like/unlike
    } else {
      print('Error toggling like: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

  Future<void> removeComment(String reviewId, String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/reviews/$reviewId/comments/$commentId'),
      );

      if (response.statusCode == 200) {
        fetchReviews(); // Refresh reviews after removing comment
      } else {
        print('Error removing comment: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.hour}:${date.minute} ${date.day}/${date.month}/${date.year}";
  }

  Widget _buildUserReviews(List<dynamic> reviews) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: reviews.map((review) {
      final reviewId = review['reviewId'];
      final userIDliked = List<String>.from(review['userIDliked'] ?? []);
      TextEditingController _commentController = TextEditingController();

      return Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review["userPhotoUrl"] != null
                      ? NetworkImage(review["userPhotoUrl"])
                      : null,
                  child: review["userPhotoUrl"] == null
                      ? Icon(Icons.person, size: 30)
                      : null,
                  radius: 20,
                ),
                SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["userFullName"] ?? review["userName"] ?? "Unknown",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.0),
            _buildListItem("Review", review["reviewText"]),
            _buildListItem("Rating", review["rating"]),
            _buildListItem(
              "Timestamp",
              review["timestamp"] != null
                  ? formatTimestamp(review["timestamp"]["seconds"])
                  : "Not provided",
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Likes: ${review['noOfLikes']}", style: TextStyle(fontSize: 14)),
                    IconButton(
                      icon: Icon(
                        userIDliked.contains(widget.username)
                            ? Icons.thumb_up
                            : Icons.thumb_up_off_alt,
                        color: userIDliked.contains(widget.username)
                            ? Colors.blueAccent
                            : Colors.black,
                      ),
                      onPressed: () => addLike(widget.username, reviewId, userIDliked),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showComments[reviewId] = !(showComments[reviewId] ?? false);
                    });
                  },
                  child: Text("Comments"),
                ),
              ],
            ),
            if (showComments[reviewId] == true) ...[
              ...review['comments']?.map<Widget>((comment) {
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
              [Text("No comments available.")],
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
                      addComment(reviewId, _commentController.text, widget.username);
                      _commentController.clear();
                    }
                  },
                  child: Text("Post Comment"),
                ),
              ),
            ]
          ],
        ),
      );
    }).toList(),
  );
}


  Widget _buildListItem(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value?.toString() ?? "Not provided")),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: fetchCounsellorFullName(widget.username),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Loading..."),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      } else if (snapshot.hasError) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Error"),
          ),
          body: Center(child: Text("Failed to fetch counsellor name.")),
        );
      } else {
        String counsellorFullName = snapshot.data ?? "Unknown";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text("Reviews To $counsellorFullName"),
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    userReviews.isEmpty
                        ? Center(child: Text("No reviews available."))
                        : Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(8.0),
                              child: _buildUserReviews(userReviews),
                            ),
                          ),
                  ],
                ),
        );
      }
    },
  );
}
}
