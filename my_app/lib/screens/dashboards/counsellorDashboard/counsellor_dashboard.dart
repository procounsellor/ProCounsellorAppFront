import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';
import 'dart:convert';
import 'client_details_page.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CounsellorDashboard extends StatefulWidget {
  final VoidCallback onSignOut;
  final double earnings = 150.0;
  final String counsellorId;

  CounsellorDashboard({required this.onSignOut, required this.counsellorId});

  @override
  _CounsellorDashboardState createState() => _CounsellorDashboardState();
}

class _CounsellorDashboardState extends State<CounsellorDashboard> {
  bool isLoading = true;
  List<dynamic> clients = [];
  List<dynamic> filteredClients = [];
  String counsellorName = "";
  double earnings = 150.0;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    fetchReviews();
  }

  Future<void> fetchDashboardData() async {
    final clientUrl = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients');
    final detailsUrl = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}');

    try {
      final clientResponse = await http.get(clientUrl);
      final detailsResponse = await http.get(detailsUrl);

      if (clientResponse.statusCode == 200 &&
          detailsResponse.statusCode == 200) {
        setState(() {
          clients = json.decode(clientResponse.body);
          filteredClients = clients;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch data")),
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

  Future<void> fetchReviews() async {
    final url = Uri.parse(
        'http://localhost:8080/api/reviews/counsellor/${widget.counsellorId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print("Failed to fetch reviews");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  void filterClients(String query) {
    setState(() {
      filteredClients = clients
          .where((client) => client['firstName']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: filterClients,
                      decoration: InputDecoration(
                        hintText: "Search subscribers...",
                        prefixIcon: Icon(Icons.search, color: Colors.orange),
                        fillColor: Color(0xFFFFF3E0),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color.fromARGB(255, 16, 15, 15)
                          .withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Subscribers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            filteredClients.isEmpty
                                ? Center(
                                    child: Text("No subscribed clients found."),
                                  )
                                : SizedBox(
                                    height: 160,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filteredClients.length,
                                      itemBuilder: (context, index) {
                                        final client = filteredClients[index];
                                        return Card(
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                          ),
                                          elevation: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ClientDetailsPage(
                                                    client: client,
                                                    counsellorId:
                                                        widget.counsellorId,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              width: 100,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.orange,
                                                        width: 1,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: CircleAvatar(
                                                      radius: 30,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        client['photo'] ??
                                                            'https://via.placeholder.com/150',
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    client['firstName'] ??
                                                        "Unknown",
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                  SizedBox(height: 6),
                                                  // Button-like text for "Contact"
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(
                                                              0.1), // Light green background
                                                      border: Border.all(
                                                        color: Colors
                                                            .green, // Green border
                                                        width: 1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    child: Text(
                                                      "Contact",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  //earning section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Earnings",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.currency_rupee,
                                            color: Colors.green, size: 24),
                                        Text(
                                          widget.earnings.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: Text("Withdraw"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.orange.withOpacity(0.9),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "My Reviews",
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                reviews.isEmpty
                                    ? Center(child: CircularProgressIndicator())
                                    : CarouselSlider(
                                        options: CarouselOptions(
                                            height: 200.0, autoPlay: true),
                                        items: reviews.map((review) {
                                          return Card(
                                            color: Colors.white,
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                            ),
                                            child: Column(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0),
                                                  child: Image.network(
                                                    review['userPhotoUrl'],
                                                    height: 80,
                                                    width: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children:
                                                      List.generate(5, (index) {
                                                    return Icon(
                                                        index < review['rating']
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: Colors.orange);
                                                  }),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  (review['reviewText'] ??
                                                              "No review available.")
                                                          .split(" ")
                                                          .take(10)
                                                          .join(" ") +
                                                      "...",
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MyReviewPage(
                                              username: widget.counsellorId),
                                        ),
                                      );
                                    },
                                    child: Text("Go to My Reviews"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // review section
                ],
              ),
            ),
    );
  }
}
