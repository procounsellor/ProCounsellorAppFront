import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/post_review.dart';
import 'package:ProCounsellor/screens/newCallingScreen/video_call_screen.dart';
import 'dart:convert'; // For encoding/decoding JSON
import '../../../services/api_utils.dart';
import '../../newCallingScreen/audio_call_screen.dart';
import '../../newCallingScreen/firebase_notification_service.dart';
import '../../newCallingScreen/save_fcm_token.dart';
import '../../paymentScreens/add_funds.dart';
import '../../paymentScreens/transfer_funds.dart';
import 'chatting_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class DetailsPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final bool isNews;
  final Map<String, dynamic>? counsellor;
  final Future<void> Function() onSignOut;

  DetailsPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
    this.counsellor,
    this.isNews = false,
    required this.onSignOut,
  });

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool isSubscribed = false; // Track subscription status
  bool isFollowed = false; // Track following status
  bool isLoading = true; // Track loading status for API calls
  Map<String, dynamic>? counsellorDetails; // Store fetched counsellor details
  Map<String, dynamic>? userDetails;
  List<dynamic> reviews = [];
  Map<String, bool> showComments = {};
  List<Map<String, dynamic>> clientDetailsList = [];
  bool isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    fetchCounsellorDetails(); // Fetch counsellor details on page load
    fetchUserDetails();
    checkSubscriptionStatus(); // Check subscription status on page load
    checkFollowingStatus(); // Check following status on page load
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiUtils.baseUrl}/api/reviews/counsellor/${widget.counsellorId}'));
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
    final url =
        Uri.parse('${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}');

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
      fetchClientDetails();
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

   Future<void> fetchUserDetails() async {
     final url = Uri.parse(
         '${ApiUtils.baseUrl}/api/user/${widget.userId}');
 
     try {
       final response = await http.get(url);
 
       if (response.statusCode == 200) {
         setState(() {
           userDetails = json.decode(response.body);
           isLoading = false;
         });
       } else {
         setState(() {
           isLoading = false; // Stop loading even if there's an error
         });
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed to fetch user details")),
         );
       }
     } catch (e) {
       setState(() {
         isLoading = false;
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Error: $e")),
       );
     }
   }

  Future<void> fetchClientDetails() async {
    final clientIdsRaw = counsellorDetails?['clientIds'];
    print(counsellorDetails?['clientIds']);
    if (clientIdsRaw == null || clientIdsRaw is! List) {
      setState(() {
        clientDetailsList = [];
        isLoadingClients = false;
      });
      return;
    }
    final List<dynamic> clientIds = clientIdsRaw;
    List<Map<String, dynamic>> tempList = [];

    for (String clientId in clientIds) {
      final url = "${ApiUtils.baseUrl}/api/user/$clientId";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          tempList.add(userData);
        }
      } catch (e) {
        print("Failed to load client $clientId: $e");
      }
    }

    setState(() {
      clientDetailsList = tempList;
      isLoadingClients = false;
    });
  }

  // Function to check if the user is already subscribed to the counsellor
  Future<void> checkSubscriptionStatus() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/is-subscribed/${widget.counsellorId}');

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
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/has-followed/${widget.counsellorId}');

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

   Future<void> handleConditionalSubscription() async {
   final userWallet = (userDetails?['walletAmount'] ?? 0).toDouble();
   final ratePerYear = (counsellorDetails?['ratePerYear'] ?? 0).toDouble();
 
   if (userWallet >= ratePerYear) {
     // ✅ Sufficient funds, proceed to transfer and subscribe
     final result = await Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => TransferFundsPage(
           userId: widget.userId,
           counsellorId: widget.counsellorId,
           amount: ratePerYear,
         ),
       ),
     );
 
     if (result == true) {
       await subscribe(); // Call subscribe after successful transfer
     }
 
   } else {
     // ❌ Insufficient funds, redirect to add funds
     final result = await Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => AddFundsPage(userName: widget.userId),
       ),
     );
 
     if (result == true) {
       // Re-fetch user details after adding funds
       await fetchUserDetails();
 
       final updatedWallet = (userDetails?['walletAmount'] ?? 0).toDouble();
       if (updatedWallet >= ratePerYear) {
         // Proceed to transfer after topping up
         final transferResult = await Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => TransferFundsPage(
               userId: widget.userId,
               counsellorId: widget.counsellorId,
               amount: ratePerYear,
             ),
           ),
         );
 
         if (transferResult == true) {
           await subscribe(); // Subscribe after transfer
         }
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Still insufficient balance after adding funds")),
         );
       }
     }
   }
 }
 

  // Function to call the subscribe API
  Future<void> subscribe() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/subscribe/${widget.counsellorId}');

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
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/unsubscribe/${widget.counsellorId}');

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
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/follow/${widget.counsellorId}');

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
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/unfollow/${widget.counsellorId}');

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

// Function to calculate ratings summary
  Map<String, dynamic> calculateRatingSummary(List<dynamic> reviews) {
    int totalRatings = reviews.length;
    double averageRating = 0.0;
    Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      if (review is Map<String, dynamic>) {
        int rating = (review['rating'] ?? 0).toInt();
        if (rating > 0 && rating <= 5) {
          starCounts[rating] = (starCounts[rating] ?? 0) + 1;
          averageRating += rating;
        }
      }
    }

    if (totalRatings > 0) {
      averageRating /=
          totalRatings.toDouble();
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
                style: GoogleFonts.outfit(
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
                    "$totalRatings ratings",
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
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
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.bold),
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
                      style:
                          GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
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
          // title: Text(widget.itemName,
          //     style: GoogleFonts.outfit(color: Colors.black)),
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

                        // Image
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row with image and details
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: Image
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        counsellorDetails?['photoUrl'] ??
                                            'https://via.placeholder.com/150',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),

                                // Right: Name + Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${counsellorDetails?['firstName'] ?? 'N/A'} ${counsellorDetails?['lastName'] ?? ''}",
                                        style: GoogleFonts.outfit(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Organisation: ${counsellorDetails?['organisationName'] ?? 'N/A'}",
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                      Text(
                                        "Experience: ${counsellorDetails?['experience'] ?? 'N/A'} years",
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                      Text(
                                        "Subscription: ₹ ${counsellorDetails?['ratePerYear'] ?? 'N/A'} per year",
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Pull this outside the row to align left with image
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 0), // No extra indent
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "EXPERTISE",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    (counsellorDetails?['expertise'] as List<dynamic>? ?? []).join(', '),
                                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                            height: 16), // Space between full name and buttons
                        // Add this above your square buttons
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed:
                                    isSubscribed ? unsubscribe : handleConditionalSubscription,
                                icon: Icon(
                                  isSubscribed
                                      ? Icons.cancel
                                      : Icons.subscriptions,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  isSubscribed ? "UNSUBSCRIBE" : "SUBSCRIBE",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        6), // Slight rounding
                                  ),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        buildActionButtonsRow(),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "RECIPIENTS",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                        if (isLoadingClients)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5, // Show 5 shimmer items
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Container(
                                          width: 60,
                                          height: 10,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else if (clientDetailsList.isEmpty)
                          Text("No clients found.")
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: clientDetailsList.length,
                              itemBuilder: (context, index) {
                                final user = clientDetailsList[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(
                                          user['photo'] ??
                                              'https://via.placeholder.com/150',
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        user['firstName'] ??
                                            user['userName'] ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        // Expertise, Subscribe, and Follow Buttons Row
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     // Subscribe Button
                        //     ElevatedButton.icon(
                        //       onPressed: isSubscribed ? unsubscribe : subscribe,
                        //       icon: Icon(
                        //         isSubscribed
                        //             ? Icons.cancel
                        //             : Icons.subscriptions,
                        //         color: Colors.white,
                        //         size: 16,
                        //       ),
                        //       label: Text(
                        //         isSubscribed ? "Unsubscribe" : "Subscribe",
                        //         style: GoogleFonts.outfit(
                        //             color: Colors.white, fontSize: 12),
                        //       ),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.orange
                        //             .withOpacity(0.7), // Tinted orange button
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: EdgeInsets.symmetric(
                        //             horizontal: 8, vertical: 6),
                        //       ),
                        //     ),

                        //     // Follow Button
                        //     ElevatedButton.icon(
                        //       onPressed: isFollowed ? unfollow : follow,
                        //       icon: Icon(
                        //         isFollowed ? Icons.cancel : Icons.subscriptions,
                        //         color: Colors.white,
                        //         size: 16,
                        //       ),
                        //       label: Text(
                        //         isFollowed ? "Unfollow" : "Follow",
                        //         style: GoogleFonts.outfit(
                        //             color: Colors.white, fontSize: 12),
                        //       ),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.orange
                        //             .withOpacity(0.7), // Tinted orange button
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: EdgeInsets.symmetric(
                        //             horizontal: 8, vertical: 6),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(
                        //     height:
                        //         16), // Space between buttons and information

                        // // Additional Information

                        // SizedBox(
                        //     height:
                        //         16), // Space between information and buttons

                        // // Call, Chat, and Video Call Buttons Row
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     // Call Button
                        //     ElevatedButton.icon(
                        //       onPressed: isSubscribed
                        //           ? () async {
                        //               String receiverId = widget.counsellorId;
                        //               String senderName = widget.userId;
                        //               String channelId =
                        //                   "audio_${DateTime.now().millisecondsSinceEpoch}";

                        //               // ✅ Get Receiver's FCM Token from Firestore
                        //               String? receiverFCMToken =
                        //                   await FirestoreService
                        //                       .getFCMTokenCounsellor(
                        //                           receiverId);

                        //               await FirebaseNotificationService
                        //                   .sendCallNotification(
                        //                       receiverFCMToken:
                        //                           receiverFCMToken!,
                        //                       senderName: senderName,
                        //                       channelId: channelId,
                        //                       receiverId: receiverId,
                        //                       callType: "audio");

                        //               Navigator.push(
                        //                 context,
                        //                 MaterialPageRoute(
                        //                   builder: (context) => AudioCallScreen(
                        //                     channelId: channelId,
                        //                     isCaller: true,
                        //                     callerId: senderName,
                        //                     receiverId: receiverId,
                        //                     onSignOut: widget.onSignOut,
                        //                   ),
                        //                 ),
                        //               );
                        //             }
                        //           : null, // Disable button if not subscribed
                        //       icon: Icon(Icons.call, size: 16),
                        //       label:
                        //           Text("Call", style: GoogleFonts.outfit(fontSize: 12)),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.green[300],
                        //         foregroundColor:
                        //             Colors.black, // Green hue button
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: EdgeInsets.symmetric(
                        //             horizontal: 12, vertical: 8),
                        //       ),
                        //     ),

                        //     // Chat Button
                        //     ElevatedButton.icon(
                        //       onPressed: isSubscribed
                        //           ? () {
                        //               Navigator.push(
                        //                 context,
                        //                 MaterialPageRoute(
                        //                   builder: (_) => UserChattingPage(
                        //                     itemName: widget.itemName,
                        //                     userId: widget.userId,
                        //                     counsellorId: widget.counsellorId,
                        //                     onSignOut: widget.onSignOut,
                        //                   ),
                        //                 ),
                        //               );
                        //             }
                        //           : null, // Disable button if not subscribed
                        //       icon: Icon(Icons.chat, size: 16),
                        //       label:
                        //           Text("Chat", style: GoogleFonts.outfit(fontSize: 12)),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor:
                        //             Colors.green[300], // Green hue button
                        //         foregroundColor: Colors.black,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: EdgeInsets.symmetric(
                        //             horizontal: 12, vertical: 8),
                        //       ),
                        //     ),

                        //     // Video Call Button
                        //     ElevatedButton.icon(
                        //       onPressed: isSubscribed
                        //           ? () async {
                        //               String receiverId = widget.counsellorId;
                        //               String senderName = widget.userId;
                        //               String channelId =
                        //                   "video_${DateTime.now().millisecondsSinceEpoch}";

                        //               // ✅ Get Receiver's FCM Token from Firestore.
                        //               String? receiverFCMToken =
                        //                   await FirestoreService
                        //                       .getFCMTokenCounsellor(
                        //                           receiverId);

                        //               await FirebaseNotificationService
                        //                   .sendCallNotification(
                        //                       receiverFCMToken:
                        //                           receiverFCMToken!,
                        //                       senderName: senderName,
                        //                       channelId: channelId,
                        //                       receiverId: receiverId,
                        //                       callType: "video");

                        //               Navigator.push(
                        //                 context,
                        //                 MaterialPageRoute(
                        //                   builder: (context) => VideoCallScreen(
                        //                     channelId: channelId,
                        //                     isCaller: true,
                        //                     callerId: senderName,
                        //                     receiverId: receiverId,
                        //                     onSignOut: widget.onSignOut,
                        //                   ),
                        //                 ),
                        //               );
                        //             }
                        //           : null, // Disable button if not subscribed
                        //       icon: Icon(Icons.video_call, size: 16),
                        //       label: Text("Video Call",
                        //           style: GoogleFonts.outfit(fontSize: 12),
                        //           selectionColor: Colors.white),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor:
                        //             Colors.green[300], // Green hue button
                        //         foregroundColor: Colors.black,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         padding: EdgeInsets.symmetric(
                        //             horizontal: 12, vertical: 8),
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        SizedBox(height: 20),
                        // Reviews Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "REVIEWS",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                        // SizedBox(height: 15),

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
                                                style: GoogleFonts.outfit(
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
                                                (review["rating"] ?? 0)
                                                    .toInt(), // Convert rating to int safely
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
                                            style: GoogleFonts.outfit(
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
                                                hintStyle: GoogleFonts.outfit(
                                                    color: Colors.grey[500]),
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: BorderSide(
                                                      color: Colors.orange,
                                                      width: 1.5),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(Icons.send,
                                                      color: Colors.orange),
                                                  onPressed: () {
                                                    if (_commentController
                                                        .text.isNotEmpty) {
                                                      addComment(
                                                          reviewId,
                                                          _commentController
                                                              .text,
                                                          widget.userId);
                                                      _commentController
                                                          .clear();
                                                    }
                                                  },
                                                ),
                                              ),
                                              textInputAction:
                                                  TextInputAction.done,
                                              onSubmitted: (value) {
                                                if (value.isNotEmpty) {
                                                  addComment(reviewId, value,
                                                      widget.userId);
                                                  _commentController.clear();
                                                }
                                              },
                                              style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  color: Colors.black),
                                              cursorColor: Colors.orange,
                                              maxLines: 3,
                                              minLines: 1,
                                              keyboardType:
                                                  TextInputType.multiline,
                                            ),
                                            // Align(
                                            //   alignment: Alignment.centerRight,
                                            //   child: TextButton(
                                            //     onPressed: () {
                                            //       if (_commentController
                                            //           .text.isNotEmpty) {
                                            //         addComment(
                                            //             reviewId,
                                            //             _commentController.text,
                                            //             widget.userId);
                                            //         _commentController.clear();
                                            //       }
                                            //     },
                                            //     child: Text("Post Comment"),
                                            //   ),
                                            // ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              )
                            : Text(
                                "No reviews available.",
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: Colors.grey),
                              ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        // Reviews Heading

                        // Post Review Button and View More
                        Column(
                          children: [
                            // Post Review Button
                            // ElevatedButton(
                            //   onPressed: isSubscribed
                            //       ? () async {
                            //           final result = await Navigator.push(
                            //             context,
                            //             MaterialPageRoute(
                            //               builder: (_) => PostUserReview(
                            //                 userName: widget.userId,
                            //                 counsellorName:
                            //                     widget.counsellorId,
                            //               ),
                            //             ),
                            //           );
                            //           if (result == true) {
                            //             fetchReviews(); // Reload reviews on return
                            //           }
                            //         }
                            //       : null, // Disabled if not subscribed
                            //   child: Text("Post Review"),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: isSubscribed
                            //         ? Colors
                            //             .green[300] // Enabled button color
                            //         : Colors.grey, // Disabled button color
                            //     foregroundColor: Colors.white, // Text color
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(8),
                            //     ),
                            //     padding: EdgeInsets.symmetric(
                            //         horizontal: 16, vertical: 8),
                            //   ),
                            // ),
                            SizedBox(height: 10),
                            InkWell(
                              onTap: isSubscribed
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PostUserReview(
                                            userName: widget.userId,
                                            counsellorName: widget.counsellorId,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        fetchReviews(); // Reload reviews on return
                                      }
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2.0, horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "POST REVIEW",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSubscribed
                                            ? Colors.grey[800]
                                            : Colors.grey[400],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: isSubscribed
                                          ? Colors.grey[700]
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 0.8,
                              indent: 12,
                              endIndent: 12,
                            ),

                            // View More Text
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MyReviewPage(
                                      username: widget.counsellorId,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2.0, horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "VIEW MORE",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

// Button to navigate to PostUserReview page
                    //   ],
                    // ),
                  ),
          ),
        ));
  }

  Widget buildActionButtonsRow() {
    final buttonData = [
      // {
      //   "icon": isSubscribed ? Icons.cancel : Icons.subscriptions,
      //   "label": isSubscribed ? "Unsubscribe" : "Subscribe",
      //   "onTap": isSubscribed ? unsubscribe : subscribe,
      // },
      {
        "icon": isFollowed ? Icons.person_remove : Icons.person_add,
        "label": isFollowed ? "Unfollow" : "Follow",
        "onTap": isFollowed ? unfollow : follow,
      },
      {
        "icon": Icons.call,
        "label": "Call",
        "onTap": isSubscribed
            ? () async {
                String receiverId = widget.counsellorId;
                String senderName = widget.userId;
                String channelId =
                    "audio_${DateTime.now().millisecondsSinceEpoch}";
                String? receiverFCMToken =
                    await FirestoreService.getFCMTokenCounsellor(receiverId);
                await FirebaseNotificationService.sendCallNotification(
                  receiverFCMToken: receiverFCMToken!,
                  senderName: senderName,
                  channelId: channelId,
                  receiverId: receiverId,
                  callType: "audio",
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioCallScreen(
                      channelId: channelId,
                      isCaller: true,
                      callerId: senderName,
                      receiverId: receiverId,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              }
            : null,
      },
      {
        "icon": Icons.chat,
        "label": "Chat",
        "onTap": isSubscribed
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserChattingPage(
                      itemName: widget.itemName,
                      userId: widget.userId,
                      counsellorId: widget.counsellorId,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              }
            : null,
      },
      {
        "icon": Icons.video_call,
        "label": "Video",
        "onTap": isSubscribed
            ? () async {
                String receiverId = widget.counsellorId;
                String senderName = widget.userId;
                String channelId =
                    "video_${DateTime.now().millisecondsSinceEpoch}";
                String? receiverFCMToken =
                    await FirestoreService.getFCMTokenCounsellor(receiverId);
                await FirebaseNotificationService.sendCallNotification(
                  receiverFCMToken: receiverFCMToken!,
                  senderName: senderName,
                  channelId: channelId,
                  receiverId: receiverId,
                  callType: "video",
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallScreen(
                      channelId: channelId,
                      isCaller: true,
                      callerId: senderName,
                      receiverId: receiverId,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              }
            : null,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 40) / 4;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: buttonData.map((btn) {
              final isLockedFeature =
                  ["Call", "Chat", "Video"].contains(btn['label']) &&
                      !isSubscribed;

              final icon = btn['icon'] as IconData;
              final label = btn['label'] as String;
              final onTap = btn['onTap'] as void Function()?;

              return GestureDetector(
                  onTap: isLockedFeature ? null : onTap,
                  child: Container(
                    width: itemWidth,
                    height: itemWidth,
                    decoration: BoxDecoration(
                      color:
                          isLockedFeature ? Colors.grey[300] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color:
                              isLockedFeature ? Colors.grey[600] : Colors.black,
                        ),
                        SizedBox(height: 6),
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isLockedFeature
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ));
            }).toList(),
          ),
        );
      },
    );
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
                  '${ApiUtils.baseUrl}/api/reviews/$userId/$reviewId/unlike'),
            ) // Unliking
          : await http.post(
              Uri.parse(
                  '${ApiUtils.baseUrl}/api/reviews/$userId/$reviewId/like'),
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
            '${ApiUtils.baseUrl}/api/reviews/$reviewId/comments/$commentId'),
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
}