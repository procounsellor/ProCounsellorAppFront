import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_reviews.dart';

import 'package:my_app/screens/dashboards/counsellorDashboard/followers_page.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/subscribers_page.dart';

import '../../../services/api_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

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
                      // Counsellor Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          profileData!['description'] ?? "Not provided",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Profile Details
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildListItem(
                                  "Organisation",
                                  profileData!["organisationName"],
                                  Icons.business),
                              _buildListItem("Experience",
                                  profileData!["experience"], Icons.work),
                              _buildListItem(
                                  "State",
                                  profileData!["stateOfCounsellor"],
                                  Icons.location_on),
                              _buildListItem("Expertise",
                                  profileData!["expertise"], Icons.star),
                              _buildListItem(
                                  "Rate Per Year",
                                  profileData!["ratePerYear"],
                                  Icons.attach_money),
                              _buildListItem(
                                  "Languages Known",
                                  profileData!["languagesKnow"]?.join(", ") ??
                                      "Not provided",
                                  Icons.language),
                            ],
                          ),
                        ),
                      ),
                    ],
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
