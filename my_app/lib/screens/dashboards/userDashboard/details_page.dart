import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';
import 'package:my_app/screens/dashboards/userDashboard/call_page.dart';
import 'package:my_app/screens/dashboards/userDashboard/post_review.dart';
import 'package:my_app/services/call_service.dart';
import 'package:my_app/services/video_call_service.dart';
import 'dart:convert'; // For encoding/decoding JSON
import 'chatting_page.dart';
import 'video_call_page.dart';

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
  final CallService _callService = CallService();

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
          isLoading = false;
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

  void _startCall() async {
    String callerId = widget.userId;
    String receiverId = widget.counsellorId;

    if (callerId.isEmpty || receiverId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter both IDs")));
      return;
    }

    String? callId =
        await _callService.startCall(callerId, receiverId, "audio");
    if (callId != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                  callId: callId,
                  id: widget.userId,
                  isCaller: true,
                  callInitiatorId: widget.counsellorId)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Call failed")));
    }
  }

  void _startVideoCall(BuildContext context) async {
    final VideoCallService _callService = VideoCallService();
    String callerId = widget.userId;
    String receiverId = widget.counsellorId;

    if (callerId.isEmpty || receiverId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter both IDs")));
      return;
    }

    String? callId =
        await _callService.startCall(callerId, receiverId, "video");
    if (callId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            callId: callId,
            id: widget.counsellorId,
            isCaller: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Call failed")));
    }
  }

  //review summary section
// Function to calculate ratings summary
  Map<String, dynamic> calculateRatingSummary(List<dynamic> reviews) {
    int totalRatings = reviews.length;
    double averageRating = 0.0;
    Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        int rating = review['rating'] ?? 0;
        if (rating > 0 && rating <= 5) {
          starCounts[rating] = (starCounts[rating] ?? 0) + 1;
          averageRating += rating;
        }
      }
    }

    if (totalRatings > 0) {
      averageRating /= totalRatings;
    }

    return {
      "averageRating": averageRating,
      "totalRatings": totalRatings,
      "starCounts": starCounts,
    };
  }

// Widget for Rating Summary
  Widget buildRatingSummary(List<Map<String, dynamic>> reviews) {
    final ratingSummary = calculateRatingSummary(reviews);

    double averageRating = ratingSummary['averageRating'];
    int totalRatings = ratingSummary['totalRatings'];
    Map<int, int> starCounts = ratingSummary['starCounts'];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating and Total Reviews
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        color: index < averageRating.round()
                            ? Colors.orange
                            : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "$totalRatings orders",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 16),

          // Star Rating Breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                int star = 5 - index;
                int count = starCounts[star] ?? 0;
                double percentage =
                    totalRatings > 0 ? (count / totalRatings) * 100 : 0;

                return Row(
                  children: [
                    Text(
                      "$star",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[300],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: star == 5
                                  ? Colors.green
                                  : star == 4
                                      ? Colors.lightGreen
                                      : star == 3
                                          ? Colors.amber
                                          : star == 2
                                              ? Colors.orange
                                              : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      count.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // summary section end

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(widget.itemName, style: TextStyle(color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
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
                        // Required for the glassy effect

                        Container(
                          width: double.infinity, // Full width of the page
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Image
                              Container(
                                width: MediaQuery.of(context).size.width *
                                    0.8, // Cover 80% of card width
                                height: MediaQuery.of(context).size.width *
                                    0.7, // Increased height
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      counsellorDetails?['photoUrl'] ??
                                          'https://via.placeholder.com/150',
                                      // Fallback image
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.7),
                                      width: 2), // Tinted orange border
                                ),
                              ),
                              SizedBox(
                                  height:
                                      16), // Space between image and full name

                              // Full Name
                              Text(
                                "${counsellorDetails?['firstName'] ?? 'N/A'} ${counsellorDetails?['lastName'] ?? ''}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize:
                                      22, // Slightly larger font for the name
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height:
                                      16), // Space between full name and buttons

                              // Expertise, Subscribe, and Follow Buttons Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Expertise Button
                                  TextButton(
                                    onPressed: () {
                                      showGeneralDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel:
                                            MaterialLocalizations.of(context)
                                                .modalBarrierDismissLabel,
                                        pageBuilder: (BuildContext context,
                                            Animation<double> animation,
                                            Animation<double>
                                                secondaryAnimation) {
                                          final expertiseList =
                                              counsellorDetails?['expertise']
                                                      as List<dynamic>? ??
                                                  [];
                                          return Center(
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              padding: EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: Colors.orange
                                                        .withOpacity(0.7),
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orange
                                                        .withOpacity(0.3),
                                                    blurRadius: 20,
                                                    spreadRadius: 1,
                                                    offset: Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Expertise",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color:
                                                            Colors.orange[800],
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: expertiseList
                                                            .map((expertise) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        4.0),
                                                            child: Text(
                                                              "- $expertise",
                                                              style: TextStyle(
                                                                  fontSize: 16),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              Colors.orange
                                                                  .withOpacity(
                                                                      0.7),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Text("Close"),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        transitionDuration:
                                            Duration(milliseconds: 300),
                                        transitionBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return ScaleTransition(
                                            scale: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutBack,
                                            ),
                                            child: child,
                                          );
                                        },
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 12),
                                      backgroundColor:
                                          Colors.orange.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Expertise",
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // Subscribe Button
                                  ElevatedButton.icon(
                                    onPressed:
                                        isSubscribed ? unsubscribe : subscribe,
                                    icon: Icon(
                                      isSubscribed
                                          ? Icons.cancel
                                          : Icons.subscriptions,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isSubscribed
                                          ? "Unsubscribe"
                                          : "Subscribe",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange
                                          .withOpacity(
                                              0.7), // Tinted orange button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                    ),
                                  ),

                                  // Follow Button
                                  ElevatedButton.icon(
                                    onPressed: isFollowed ? unfollow : follow,
                                    icon: Icon(
                                      isFollowed
                                          ? Icons.cancel
                                          : Icons.subscriptions,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isFollowed ? "Unfollow" : "Follow",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange
                                          .withOpacity(
                                              0.7), // Tinted orange button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height:
                                      16), // Space between buttons and information

                              // Additional Information
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Organisation: ${counsellorDetails?['organisationName'] ?? 'N/A'}",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Experience: ${counsellorDetails?['experience'] ?? 'N/A'} years",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Subscription: \₹ ${counsellorDetails?['ratePerYear'] ?? 'N/A'} per year",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height:
                                      16), // Space between information and buttons

                              // Call, Chat, and Video Call Buttons Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Call Button
                                  ElevatedButton.icon(
                                    onPressed: isSubscribed
                                        ? () {
                                            _startCall();
                                          }
                                        : null, // Disable button if not subscribed
                                    icon: Icon(Icons.call, size: 16),
                                    label: Text("Call",
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[300],
                                      foregroundColor:
                                          Colors.black, // Green hue button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),

                                  // Chat Button
                                  ElevatedButton.icon(
                                    onPressed: isSubscribed
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChattingPage(
                                                  itemName: widget.itemName,
                                                  userId: widget.userId,
                                                  counsellorId:
                                                      widget.counsellorId,
                                                ),
                                              ),
                                            );
                                          }
                                        : null, // Disable button if not subscribed
                                    icon: Icon(Icons.chat, size: 16),
                                    label: Text("Chat",
                                        style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.green[300], // Green hue button
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),

                                  // Video Call Button
                                  ElevatedButton.icon(
                                    onPressed: isSubscribed
                                        ? () {
                                            _startVideoCall(context);
                                          }
                                        : null, // Disable button if not subscribed
                                    icon: Icon(Icons.video_call, size: 16),
                                    label: Text("Video Call",
                                        style: TextStyle(fontSize: 12),
                                        selectionColor: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.green[300], // Green hue button
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
                        // Reviews Section

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reviews Heading
                            Text(
                              "Reviews",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),

                            // Post Review Button and View More
                            Row(
                              children: [
                                // Post Review Button
                                ElevatedButton(
                                  onPressed: isSubscribed
                                      ? () {
                                          // Navigate to the Post Review Page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PostUserReview(
                                                userName: widget.userId,
                                                counsellorName:
                                                    widget.counsellorId,
                                              ),
                                            ),
                                          );
                                        }
                                      : null, // Disabled if not subscribed
                                  child: Text("Post Review"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubscribed
                                        ? Colors
                                            .green[300] // Enabled button color
                                        : Colors.grey, // Disabled button color
                                    foregroundColor: Colors.black, // Text color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),

                                // View More Text
                                if (reviews.length > 2)
                                  TextButton(
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
                                    child: Text("View More"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        buildRatingSummary(
                            reviews.cast<Map<String, dynamic>>()),
                        SizedBox(height: 10),
                        reviews.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show first two reviews
                                  ...reviews.take(2).map((review) {
                                    final reviewId = review['reviewId'];
                                    final userIDliked = List<String>.from(
                                        review['userIDliked'] ?? []);
                                    TextEditingController _commentController =
                                        TextEditingController();

                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: 6.0), // Reduced margin
                                      padding:
                                          EdgeInsets.all(10), // Reduced padding
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // User Info
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  review["userPhotoUrl"] ??
                                                      'https://via.placeholder.com/150',
                                                ),
                                                radius: 20,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                review["userFullName"] ??
                                                    review["userName"],
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),

                                          // Rating Stars
                                          Row(
                                            children: [
                                              ...List.generate(
                                                review["rating"] ??
                                                    0, // Generate stars based on rating
                                                (index) => Icon(Icons.star,
                                                    color: Colors.orange,
                                                    size: 16),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),

                                          // Review Text
                                          Text(
                                            review["reviewText"] ??
                                                "No review text provided.",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),
                                          SizedBox(height: 6), // Reduced space

                                          // Like and Comments
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      userIDliked.contains(
                                                              widget.userId)
                                                          ? Icons.heart_broken
                                                          : Icons.favorite,
                                                      color: userIDliked
                                                              .contains(
                                                                  widget.userId)
                                                          ? Colors.blueAccent
                                                          : const Color
                                                              .fromARGB(
                                                              255, 222, 20, 20),
                                                    ),
                                                    onPressed: () => addLike(
                                                        widget.userId,
                                                        reviewId,
                                                        userIDliked),
                                                  ),
                                                  Text(
                                                      "${review['noOfLikes']}"),
                                                ],
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showComments[reviewId] =
                                                        !(showComments[
                                                                reviewId] ??
                                                            false);
                                                  });
                                                },
                                                child: Text("Comments"),
                                              ),
                                            ],
                                          ),

                                          // Comments Section
                                          if (showComments[reviewId] ==
                                              true) ...[
                                            ...review["comments"]
                                                    ?.map<Widget>((comment) {
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage: comment[
                                                                  'photoUrl'] !=
                                                              null
                                                          ? NetworkImage(
                                                              comment[
                                                                  'photoUrl'])
                                                          : null,
                                                      child:
                                                          comment['photoUrl'] ==
                                                                  null
                                                              ? Icon(
                                                                  Icons.person,
                                                                  size: 20)
                                                              : null,
                                                      radius: 15,
                                                    ),
                                                    title: Text(comment[
                                                            'userFullName'] ??
                                                        comment['userName']),
                                                    subtitle: Text(comment[
                                                            'commentText'] ??
                                                        ""),
                                                  );
                                                })?.toList() ??
                                                [
                                                  Text("No comments available.")
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
                                                  if (_commentController
                                                      .text.isNotEmpty) {
                                                    addComment(
                                                        reviewId,
                                                        _commentController.text,
                                                        widget.userId);
                                                    _commentController.clear();
                                                  }
                                                },
                                                child: Text("Post Comment"),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              )
                            : Text(
                                "No reviews available.",
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),

// Button to navigate to PostUserReview page
                      ],
                    ),
                  ),
          ),
        ));
  }

  Future<void> addComment(
      String reviewId, String commentText, String username) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:8080/api/reviews/$reviewId/comments/$username'),
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

  Future<void> addLike(
      String userId, String reviewId, List<String> userIDliked) async {
    try {
      final String userId = widget
          .userId; // Assuming userId is the username (you can change this based on your logic)

      // Check if the current user has already liked the review
      bool isLiked = userIDliked.contains(userId);

      final response = isLiked
          ? await http.post(
              Uri.parse(
                  'http://localhost:8080/api/reviews/$userId/$reviewId/unlike'),
            ) // Unliking
          : await http.post(
              Uri.parse(
                  'http://localhost:8080/api/reviews/$userId/$reviewId/like'),
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
        Uri.parse(
            'http://localhost:8080/api/reviews/$reviewId/comments/$commentId'),
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
