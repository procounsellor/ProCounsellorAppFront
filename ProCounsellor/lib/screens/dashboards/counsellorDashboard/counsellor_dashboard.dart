import 'package:ProCounsellor/screens/paymentScreens/withdraw_funds_counsellor.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';
import 'dart:convert';
import '../../../services/api_utils.dart';
import '../../paymentScreens/add_bank_details_counsellor.dart';
import 'client_details_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../userDashboard/top_news_carousel.dart';
import '../userDashboard/headersText/TrendingHeader.dart';
import '../userDashboard/components/TopEvents.dart';
import '../userDashboard/components/TopColleges.dart';
import '../userDashboard/components/TopExamsList.dart';
import '../userDashboard/components/TrendingCoursesList.dart';
import '../userDashboard/components/InfiniteCollegeRanking.dart';

class CounsellorDashboard extends StatefulWidget {
  final Future<void> Function() onSignOut;
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
  List<Map<String, dynamic>> reviews = [];
  double? _walletBalance;
  Map<String, dynamic>? _bankDetails;

  @override
  late void Function() myMethod;
  void _onScroll() {
    if (!mounted) return; // <-- Safe check
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      try {
        myMethod.call();
        print("call");
      } catch (e) {
        print("⚠️ Error calling myMethod: $e");
      }
    }
  }

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll); // ✅ Add this

    fetchDashboardData();
    fetchUserDetails();
    fetchReviews();
  }

  Future<void> fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['walletAmount'] != null && data['bankDetails'] != null) {
          _walletBalance = (data['walletAmount'] ?? 0).toDouble();
          _bankDetails = data['bankDetails'];
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> fetchDashboardData() async {
    final clientUrl = Uri.parse(
        '${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}/clients');
    final detailsUrl =
        Uri.parse('${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}');

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
        '${ApiUtils.baseUrl}/api/reviews/counsellor/${widget.counsellorId}');
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
              controller: _scrollController, // Attach controller here ✅
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
                                                    onSignOut: widget.onSignOut,
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
                                                      backgroundImage: client[
                                                                      'photo'] !=
                                                                  null &&
                                                              client['photo']
                                                                  .isNotEmpty
                                                          ? NetworkImage(
                                                              client['photo'])
                                                          : AssetImage(
                                                                  'assets/images/5857.jpg')
                                                              as ImageProvider, // ✅ Asset fallback
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
                                          _walletBalance.toString(),
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
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WithdrawFundsCounsellorPage(
                                                userName: widget.counsellorId),
                                      ),
                                    );
                                  },
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
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddBankDetailsCounsellorPage(
                                        username: widget.counsellorId),
                              ),
                            );
                          },
                          child: Card(
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
                                    "Bank Details",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 12),
                                  _bankDetails != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "Account Number: ${_bankDetails!['bankAccountNumber']}"),
                                            Text(
                                                "IFSC Code: ${_bankDetails!['ifscCode']}"),
                                            Text(
                                                "Account Holder: ${_bankDetails!['fullName']}"),
                                            SizedBox(height: 16),
                                            Text(
                                              "Tap to update",
                                              style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddBankDetailsCounsellorPage(
                                                          username: widget
                                                              .counsellorId),
                                                ),
                                              );
                                            },
                                            child: Text("Add Bank Account"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
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
                                    ? Center(child: Text("No reviews for Now!"))
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
                                                  child: review['userPhotoUrl'] !=
                                                              null &&
                                                          review['userPhotoUrl']
                                                              .isNotEmpty
                                                      ? Image.network(
                                                          review[
                                                              'userPhotoUrl'],
                                                          height: 80,
                                                          width: 80,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Image.asset(
                                                              'assets/images/5857.jpg', // ✅ Asset fallback
                                                              height: 80,
                                                              width: 80,
                                                              fit: BoxFit.cover,
                                                            );
                                                          },
                                                        )
                                                      : Image.asset(
                                                          'assets/images/5857.jpg', // ✅ Local Asset Image
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
                                    onPressed: reviews.isEmpty
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MyReviewPage(
                                                        username: widget
                                                            .counsellorId),
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
                  TrendingHeader(title: "Top News"),
                  TopNewsCarousel(),
                  SizedBox(height: 10),

                  TrendingHeader(title: "Top Events"),
                  EventCarousel(),
                  SizedBox(height: 10),

                  TrendingHeader(title: "Top Colleges"),
                  TopCollegesList(username: "counsellor"),
                  SizedBox(height: 10),

                  TrendingHeader(title: "Trending Exams"),
                  TopExamsList(username: "counsellor"),
                  SizedBox(height: 10),

                  TrendingHeader(title: "Trending Courses"),
                  SizedBox(height: 10),
                  TrendingCoursesList(),

                  // TrendingHeader(title: "Explore More"),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0), // Custom padding here
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TrendingHeader(title: "Explore More"),
                        InfiniteCollegeRanking(
                          builder: (BuildContext context,
                              void Function() methodFromChild) {
                            myMethod = methodFromChild;
                          },
                          username: "counsellor",
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
