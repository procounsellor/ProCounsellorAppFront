import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class CounsellorProfilePage extends StatefulWidget {
  final String username;

  CounsellorProfilePage({required this.username});

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
    final url = 'http://localhost:8080/api/counsellor/${widget.username}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          profileData = json.decode(response.body);
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
            'http://localhost:8080/api/counsellor/${widget.username}/photo'),
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

  Widget _buildListItem(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      value = "Not provided";
    }

    if (value is List) {
      value = value.isNotEmpty ? value.join(", ") : "None";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReviews(List<dynamic> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reviews.map((review) {
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
              _buildListItem("Counsellor Name", review["counsellorName"]),
              _buildListItem("Review", review["reviewText"]),
              _buildListItem("Rating", review["rating"]),
              _buildListItem(
                "Timestamp",
                review["timestamp"] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        review["timestamp"]["seconds"] * 1000,
                      ).toString()
                    : "Not provided",
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : profileData == null
              ? Center(child: Text("Failed to load profile data"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : (profileData!["photo"] != null
                                  ? NetworkImage(profileData!["photo"])
                                  : null) as ImageProvider?,
                          child: _profileImageBytes == null &&
                                  profileData!["photo"] == null
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),

                      // User Info
                      _buildListItem("Username", profileData!["userName"]),
                      _buildListItem("First Name", profileData!["firstName"]),
                      _buildListItem("Last Name", profileData!["lastName"]),
                      _buildListItem(
                          "Phone Number", profileData!["phoneNumber"]),
                      _buildListItem("Email", profileData!["email"]),
                      _buildListItem("Balance", profileData!["balance"]),
                      _buildListItem("Address", profileData!["address"]),
                      _buildListItem("Degree Type", profileData!["degreeType"]),
                      _buildListItem("Stream", profileData!["stream"]),
                      _buildListItem("Interested Degree",
                          profileData!["interestedDegree"]),
                      _buildListItem("Interested Colleges",
                          profileData!["interestedColleges"]),
                      _buildListItem("Interested Locations",
                          profileData!["interestedLocationsForCollege"]),
                      _buildListItem("Subscribed Counsellors",
                          profileData!["subscribedCounsellorIds"]),
                      _buildListItem("Followed Counsellors",
                          profileData!["followedCounsellorsIds"]),
                      _buildListItem("Converted", profileData!["converted"]),

                      SizedBox(height: 16),

                      // User Reviews
                      Text(
                        "User Reviews:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      profileData!["userReview"] != null &&
                              profileData!["userReview"].isNotEmpty
                          ? _buildUserReviews(profileData!["userReview"])
                          : Text("No reviews available."),
                    ],
                  ),
                ),
    );
  }
}
