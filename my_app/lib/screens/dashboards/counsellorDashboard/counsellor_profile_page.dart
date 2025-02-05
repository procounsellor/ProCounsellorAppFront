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
      child: Text(
        value.toString(),
        style: TextStyle(color: Colors.black87, fontSize: 16),
      ),
    );
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
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
                      SizedBox(height: 10),
                      Text(
                        "${profileData!["firstName"]} ${profileData!["lastName"]}",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
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
                                  "Phone Number", profileData!["phoneNumber"]),
                              _buildListItem("Email", profileData!["email"]),
                              _buildListItem("Organisation Name",
                                  profileData!["organisationName"]),
                              _buildListItem(
                                  "Experience", profileData!["experience"]),
                              _buildListItem("State of Counsellor",
                                  profileData!["stateOfCounsellor"]),
                              _buildListItem(
                                  "Expertise", profileData!["expertise"]),
                              _buildListItem(
                                  "Rate Per Year", profileData!["ratePerYear"]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
