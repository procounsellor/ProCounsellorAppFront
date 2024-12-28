import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';
import 'package:my_app/screens/dashboards/userDashboard/post_review.dart';
import 'dart:convert'; // For encoding/decoding JSON
import 'chatting_page.dart';

class DetailsPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final bool isNews;
  final Map<String, dynamic>? counsellor;

  DetailsPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
    this.counsellor,
    this.isNews = false,
  });

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool isSubscribed = false; // Track subscription status
  bool isFollowed = false; // Track following status
  bool isLoading = true; // Track loading status for API calls
  Map<String, dynamic>? counsellorDetails; // Store fetched counsellor details
   List<dynamic> reviews = [];
   Map<String, bool> showComments = {};

  @override
  void initState() {
    super.initState();
    fetchCounsellorDetails(); // Fetch counsellor details on page load
    checkSubscriptionStatus(); // Check subscription status on page load
    checkFollowingStatus(); // Check following status on page load
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:8080/api/reviews/counsellor/${widget.counsellorId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          reviews = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching reviews: $e")),
      );
    }
  }

  // Function to fetch counsellor details
  Future<void> fetchCounsellorDetails() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          counsellorDetails = json.decode(response.body);
          isLoading = false; // Stop loading after fetching details
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading even if there's an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch counsellor details")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to check if the user is already subscribed to the counsellor
  Future<void> checkSubscriptionStatus() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/is-subscribed/${widget.counsellorId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final bool status = json.decode(response.body);
        setState(() {
          isSubscribed = status;
          isLoading = false; // Stop loading once the status is fetched
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading even if there's an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch subscription status")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  // Function to check if the user is already following the counsellor
  Future<void> checkFollowingStatus() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/has-followed/${widget.counsellorId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final bool status = json.decode(response.body);
        setState(() {
          isFollowed = status;
          isLoading = false; // Stop loading once the status is fetched
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading even if there's an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch subscription status")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to call the subscribe API
  Future<void> subscribe() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/subscribe/${widget.counsellorId}');

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        setState(() {
          isSubscribed = true; // Update subscription status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscribed to ${widget.itemName}!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to subscribe")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to call the unsubscribe API
  Future<void> unsubscribe() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/unsubscribe/${widget.counsellorId}');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          isSubscribed = false; // Update subscription status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unsubscribed from ${widget.itemName}!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to unsubscribe")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to call the follow API
  Future<void> follow() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/follow/${widget.counsellorId}');

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        setState(() {
          isFollowed = true; // Update following status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Followed to ${widget.itemName}!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to follow")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to call the unfollow API
  Future<void> unfollow() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/unfollow/${widget.counsellorId}');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          isFollowed = false; // Update following status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unfollow from ${widget.itemName}!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to unfollow")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.itemName),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      // Wrap content in a scrollable view
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              ) // Show loader while fetching status
            : Align(
                alignment: Alignment.center, // Ensures content is centered
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Details about ${widget.itemName}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        counsellorDetails?['photoUrl'] ??
                            'https://via.placeholder.com/150/0000FF/808080?Text=PAKAINFO.com',
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Name: ${counsellorDetails?['firstName'] ?? 'N/A'} ${counsellorDetails?['lastName'] ?? ''}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Organisation: ${counsellorDetails?['organisationName'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Specialization: ${counsellorDetails?['specialization'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Experience: ${counsellorDetails?['experience'] ?? 'N/A'} years",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Rate per Minute (Call): \$${counsellorDetails?['ratePerMinuteCall'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Rate per Minute (Video Call): \$${counsellorDetails?['ratePerMinuteVideoCall'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Rate per Minute (Chat): \$${counsellorDetails?['ratePerMinuteChat'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),

                    // Call button
                    ElevatedButton.icon(
                      onPressed: isSubscribed
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Calling ${counsellorDetails?['firstName']}...")),
                              );
                            }
                          : null, // Disable button if not subscribed
                      icon: Icon(Icons.call),
                      label: Text("Call"),
                    ),
                    SizedBox(height: 10),

                    // Chat button
                    ElevatedButton.icon(
                      onPressed: isSubscribed
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChattingPage(
                                    itemName: widget.itemName,
                                    userId: widget.userId,
                                    counsellorId: widget.counsellorId,
                                  ),
                                ),
                              );
                            }
                          : null, // Disable button if not subscribed
                      icon: Icon(Icons.chat),
                      label: Text("Chat"),
                    ),
                    SizedBox(height: 10),

                    // Video call button
                    ElevatedButton.icon(
                      onPressed: isSubscribed
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Video calling ${counsellorDetails?['firstName']}...")),
                              );
                            }
                          : null, // Disable button if not subscribed
                      icon: Icon(Icons.video_call),
                      label: Text("Video Call"),
                    ),
                    SizedBox(height: 20),

                    // Subscribe/Unsubscribe Button
                    ElevatedButton.icon(
                      onPressed: isSubscribed ? unsubscribe : subscribe,
                      icon: Icon(
                          isSubscribed ? Icons.cancel : Icons.subscriptions),
                      label: Text(isSubscribed ? "Unsubscribe" : "Subscribe"),
                    ),
                    SizedBox(height: 20),

                    //Follow/Unfollow button
                    ElevatedButton.icon(
                      onPressed: isFollowed ? unfollow : follow,
                      icon: Icon(
                          isFollowed ? Icons.cancel : Icons.subscriptions),
                      label: Text(isFollowed ? "Unfollow" : "Follow"),
                    ),
                    SizedBox(height: 20),

                    // Reviews Section
                    Text(
                      "User Reviews",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    reviews.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUserReviews(reviews.take(2).toList()),
                              if (reviews.length > 2)
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyReviewPage(
                                            username: widget.counsellorId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text("See More"),
                                  ),
                                ),
                            ],
                          )
                        : Text("No reviews available."),

                      // Button to navigate to PostUserReview page
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostUserReview(
                                  userName: widget.userId,
                                  counsellorName: widget.counsellorId,
                                ),
                              ),
                            );
                          },
                          child: Text("Post Review"),
                        ),
                      )
                  ],
                ),
              ),
      ),
    )
  );
  }




  //Need to think upon as it's reusable.....
  Widget _buildUserReviews(List<dynamic> reviews) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: reviews.map((review) {
      final reviewId = review['reviewId'];
      final userIDliked = List<String>.from(review['userIDliked'] ?? []);
      TextEditingController _commentController = TextEditingController();

      return FutureBuilder<String>(
        future: fetchUserFullName(review['userName'] ?? "Unknown"),
        builder: (context, snapshot) {
          final userFullName = snapshot.data ?? "Loading...";

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
                      backgroundImage: review["photoUrl"] != null
                          ? NetworkImage(review["photoUrl"])
                          : null,
                      child: review["photoUrl"] == null
                          ? Icon(Icons.person, size: 30)
                          : null,
                      radius: 20,
                    ),
                    SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$userFullName",
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
                            userIDliked.contains(widget.userId)
                                ? Icons.thumb_up
                                : Icons.thumb_up_off_alt,
                            color: userIDliked.contains(widget.userId)
                                ? Colors.blueAccent
                                : Colors.black,
                          ),
                          onPressed: () => addLike(widget.userId, reviewId, userIDliked),
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
                      title: Text(comment['userName'] ?? "Anonymous"),
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
                          addComment(reviewId, _commentController.text, widget.userId);
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
        },
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
    final String userId = widget.userId; // Assuming userId is the username (you can change this based on your logic)

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

  Future<String> fetchUserFullName(String userName) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/reviews/user/fullname/$userName'),
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
}
