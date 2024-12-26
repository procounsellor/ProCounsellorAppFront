import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'client_details_page.dart';
import 'all_reviews_page.dart'; // New page for all reviews

class CounsellorDashboard extends StatefulWidget {
  final VoidCallback onSignOut;
  final String counsellorId;

  CounsellorDashboard({required this.onSignOut, required this.counsellorId});

  @override
  _CounsellorDashboardState createState() => _CounsellorDashboardState();
}

class _CounsellorDashboardState extends State<CounsellorDashboard> {
  bool isLoading = true; // To track the loading state
  List<dynamic> clients = []; // To store the list of subscribed clients
  List<dynamic> reviews = []; // To store reviews
  String counsellorName = "";
  double earnings = 150.0; // Placeholder earnings value

  @override
  void initState() {
    super.initState();
    fetchDashboardData(); // Fetch data when the page loads
  }

  // Fetch clients and counsellor details
  Future<void> fetchDashboardData() async {
    final clientUrl = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients');
    final detailsUrl = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}');

    try {
      // Fetch clients
      final clientResponse = await http.get(clientUrl);
      // Fetch counsellor details
      final detailsResponse = await http.get(detailsUrl);

      if (clientResponse.statusCode == 200 &&
          detailsResponse.statusCode == 200) {
        final detailsData = json.decode(detailsResponse.body);
        setState(() {
          clients = json.decode(clientResponse.body);
          reviews = detailsData['reviews'] ?? [];
          counsellorName = detailsData['firstName'] ?? "Counsellor";
          isLoading = false; // Stop loading
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading in case of an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch data")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if an exception occurs
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Counsellor Dashboard"),
        // actions: [
        //   // IconButton(
        //   //   icon: Icon(Icons.logout),
        //   //   onPressed: widget.onSignOut, // Call the onSignOut method
        //   // ),
        // ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(), // Show loader while loading
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Welcome, $counsellorName!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Horizontal Scrollable Client List
                  clients.isEmpty
                      ? Center(
                          child: Text("No subscribed clients found."),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: clients.length,
                              itemBuilder: (context, index) {
                                final client = clients[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClientDetailsPage(
                                          client: client,
                                          counsellorId: widget.counsellorId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 100,
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(
                                            client['photo'] ??
                                                'https://via.placeholder.com/150',
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          client['firstName'] ?? "Unknown",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                  // Earnings Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Earnings",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "\$${earnings.toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Withdrawal initiated."),
                                  ),
                                );
                              },
                              child: Text("Withdraw"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Reviews",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  reviews.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("No reviews available."),
                        )
                      : Container(
                          height: 150,
                          child: Column(
                            children: [
                              if (reviews.length > 4)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AllReviewsPage(
                                          reviews: reviews,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text("See All Reviews"),
                                ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      reviews.length > 4 ? 4 : reviews.length,
                                  itemBuilder: (context, index) {
                                    final review = reviews[index];
                                    return Container(
                                      width: 150,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['userName'] ?? "Anonymous",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 16),
                                              Text("${review['rating'] ?? 0}"),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            review['reviewText'] ?? "",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
