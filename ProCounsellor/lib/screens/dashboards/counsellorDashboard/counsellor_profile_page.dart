import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';

import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/followers_page.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/subscribers_page.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/api_utils.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'counsellor_info_page.dart';

class CounsellorProfilePage extends StatefulWidget {
  final String username;
  final Future<void> Function() onSignOut;

  CounsellorProfilePage({required this.username, required this.onSignOut});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<CounsellorProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  Uint8List? _profileImageBytes;

  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> reviewList = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    fetchReviews(); // 👈 Add this
  }

  Future<List<Map<String, dynamic>>> fetchTransactionData(
      String username) async {
    final doc = await FirebaseFirestore.instance
        .collection('counsellors')
        .doc(username)
        .get();
    final transactions = List<Map<String, dynamic>>.from(doc['transactions']);
    transactions
        .sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
    return transactions;
  }

  Widget buildTransactionGraph(List<Map<String, dynamic>> transactions) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center, // brings bars closer
        groupsSpace: 18, // reduce spacing between groups
        maxY: transactions
                .map((txn) => txn['amount']?.toDouble() ?? 0)
                .reduce((a, b) => a > b ? a : b) +
            20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)), // removed top titles
          rightTitles: AxisTitles(
              sideTitles:
                  SideTitles(showTitles: false)), // removed right titles
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, _) {
                if (value.toInt() < transactions.length) {
                  final txn = transactions[value.toInt()];
                  final timestamp = txn['timestamp'];
                  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${date.day}/${date.month}",
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 50,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.black87),
            bottom: BorderSide(color: Colors.black87),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        barGroups: transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final txn = entry.value;
          final double amount = txn['amount']?.toDouble() ?? 0;
          final isCredit = txn['type'] == 'credit';

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount,
                width: 18,
                borderRadius: BorderRadius.circular(1),
                color: isCredit ? Colors.green : Colors.redAccent,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: amount + 20,
                  color: Colors.grey.shade200,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiUtils.baseUrl}/api/reviews/counsellor/${widget.username}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          reviewList = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching reviews: $e")),
      );
    }
  }

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
      averageRating /= totalRatings.toDouble();
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

  Future<void> _fetchProfileData() async {
    final url = '${ApiUtils.baseUrl}/api/counsellor/${widget.username}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileData = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (error) {
      print('Error fetching profile data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = imageBytes;
      });
      _uploadPhoto(imageBytes, image.name);
    }
  }

  Future<void> _uploadPhoto(Uint8List imageBytes, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${ApiUtils.baseUrl}/api/counsellor/${widget.username}/photo'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully!')),
        );
        _fetchProfileData(); // Refresh profile data after upload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : profileData == null
              ? Center(child: Text("Failed to load profile data"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.0),
                                color: Colors.grey[300],
                                image: _profileImageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_profileImageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : (profileData!["photoUrl"] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                profileData!["photoUrl"]),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: _profileImageBytes == null &&
                                      profileData!["photoUrl"] == null
                                  ? Icon(Icons.person,
                                      size: 60, color: Colors.white)
                                  : null,
                            ),
                          ),
                          SizedBox(width: 16),
                          // Name and Stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    "${profileData!["firstName"]} ${profileData!["lastName"]}",
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Stats
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 10),
                                    _buildStatColumn(
                                        "Clients",
                                        profileData!["clientIds"]?.length ?? 0,
                                        () => _navigateToPage(
                                              context,
                                              SubscribersPage(
                                                  counsellorId: widget.username,
                                                  onSignOut: widget.onSignOut),
                                            )),
                                    SizedBox(width: 20),
                                    _buildStatColumn(
                                      "Followers",
                                      profileData!["followerIds"]?.length ?? 0,
                                      () => _navigateToPage(
                                          context,
                                          FollowersPage(
                                            counsellorId: widget.username,
                                            onSignOut: widget.onSignOut,
                                          )),
                                    ),
                                    SizedBox(width: 20),
                                    _buildStatColumn(
                                      "Reviews",
                                      12, // Placeholder value

                                      () => _navigateToPage(
                                          context,
                                          MyReviewPage(
                                              username: widget.username)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      SizedBox(height: 20),
                      //graph
                      Text(
                        "EARNINGS",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 20),
                      FutureBuilder(
                        future: fetchTransactionData(widget.username),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text("Error loading data");
                          } else {
                            final data = snapshot.data!;
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: buildTransactionGraph(data),
                              ),
                            );
                          }
                        },
                      ),

                      Text(
                        "MY RATING",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (reviewList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: buildRatingSummary(reviewList),
                        ),

                      // Profile Details
                      // Placeholder for MY INFO
                      SizedBox(height: 20),
                      InkWell(
                        onTap: () {
                          if (profileData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CounsellorInfoPage(
                                    profileData: profileData!),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "MY INFO",
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),

                      Divider(thickness: 1.2, color: Colors.grey[300]),

                      SizedBox(height: 40), // spacing
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Confirm Logout"),
                                content:
                                    Text("Are you sure you want to logout?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text("Logout",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await widget.onSignOut();
                            }
                          },
                          icon: Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40),
                    ],
                    // bottom padding
                  ),
                ),
    );
  }

// Helper Widget for Stats with Icons
  Widget _buildStatColumn(String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // ✅ Navigation on tap
      child: Column(
        children: [
          SizedBox(height: 5),
          Text(
            "$count",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

// Helper Widget for Profile Details with Icons
  Widget _buildListItem(String title, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value != null && value.toString().isNotEmpty
                  ? value.toString()
                  : "Not provided",
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
