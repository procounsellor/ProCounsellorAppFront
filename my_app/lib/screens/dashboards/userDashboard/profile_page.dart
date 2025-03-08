import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:my_app/screens/paymentScreens/add_funds.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  ProfilePage({required this.username});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  Uint8List? _profileImageBytes;

  final ImagePicker _picker = ImagePicker();

  final List<String> allowedStates = [
    "KARNATAKA",
    "MAHARASHTRA",
    "TAMILNADU",
    "OTHERS"
  ];

  final List<String> courses = [
    "HSC",
    "ENGINEERING",
    "MEDICAL",
    "MBA",
    "OTHERS"
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final url = 'http://localhost:8080/api/user/${widget.username}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          profileData = json.decode(response.body);
          print(profileData?['photo']);
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
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = imageBytes;
        });
        _uploadPhoto(imageBytes, image.name); // Upload after picking the image
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadPhoto(Uint8List imageBytes, String fileName) async {
    final url =
        'http://localhost:8080/api/user/${widget.username}/photo'; // Ensure correct endpoint

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo', // Key for the file; ensure backend expects this key
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'), // Adjust based on image type
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully!')),
        );
        _fetchProfileData(); // Refresh profile data after successful upload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to upload photo. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updatedData) async {
    final url = 'http://localhost:8080/api/user/${widget.username}';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        _fetchProfileData(); // Refresh profile data after update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _showUpdateModal() {
    String? firstName = profileData?['firstName'];
    String? lastName = profileData?['lastName'];
    String? interestedCourse = profileData?['interestedCourse'];
    List<String> userInterestedStates = List<String>.from(
        profileData?['userInterestedStateOfCounsellors'] ?? []);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFFFCC80), // Light orange color
                  width: 4.0,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: firstName),
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          firstName = value;
                        },
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: lastName),
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          lastName = value;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: interestedCourse,
                        items: courses
                            .map((course) => DropdownMenuItem(
                                  value: course,
                                  child: Text(course),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Degree I am looking for',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            interestedCourse = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Location I am looking for',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: allowedStates.map((state) {
                          return CheckboxListTile(
                            title: Text(state),
                            value: userInterestedStates.contains(state),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  userInterestedStates.add(state);
                                } else {
                                  userInterestedStates.remove(state);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Light green color
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                          ),
                          onPressed: () {
                            Map<String, dynamic> updatedData = {
                              'firstName': firstName,
                              'lastName': lastName,
                              'interestedCourse': interestedCourse,
                              'userInterestedStateOfCounsellors':
                                  userInterestedStates,
                            };

                            _updateProfile(updatedData);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Update',
                            style: TextStyle(
                              color: Colors.black, // Black text color
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      value = "Not provided";
    }

    if (value is List) {
      value = value.isNotEmpty ? value.join(", ") : "None";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
          ),
        ],
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
                    children: [
                      // User Info Section
                      Center(
                        child: Card(
                          color: Colors.white, // White background for the card
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation:
                              5, // Add slight elevation for a shadow effect
                          child: Container(
                            width: MediaQuery.of(context).size.width *
                                0.9, // 90% of the screen width
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.35,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.35,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[
                                              300], // Placeholder background
                                          border: Border.all(
                                            color: Colors.orange,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: _profileImageBytes != null
                                              ? Image.memory(
                                                  _profileImageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : (profileData != null &&
                                                      profileData!['photo'] !=
                                                          null
                                                  ? Image.network(
                                                      profileData!['photo'],
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      size:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.2,
                                                      color: Colors.white,
                                                    )),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.orangeAccent,
                                          radius: 18,
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                if (profileData != null &&
                                    (profileData!['firstName'] != null ||
                                        profileData!['lastName'] != null))
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (profileData!['firstName'] != null)
                                        Text(
                                          profileData!['firstName'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (profileData!['lastName'] != null)
                                        SizedBox(width: 8),
                                      if (profileData!['lastName'] != null)
                                        Text(
                                          profileData!['lastName'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Additional Info Section
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Ensure even spacing
                                    children: [
                                      Text(
                                        "Wallet Balance",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.currency_rupee,
                                              color: Colors.green),
                                          SizedBox(width: 4),
                                          Text(
                                            profileData != null &&
                                                    profileData!['walletAmount'] !=
                                                        null
                                                ? profileData!['walletAmount']
                                                    .toString()
                                                : "Not provided",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          16), // Add spacing before the button
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .green, // Green color for the button
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Rounded edges
                                        ),
                                      ),
                                      onPressed: () {
                                       Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddFundsPage(userName: widget.username),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Add Funds",
                                        style: TextStyle(
                                          color:
                                              Colors.white, // White text color
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.menu_book,
                                      color: const Color.fromARGB(255, 151, 158,
                                          154)), // Icon for "Interested Course"
                                  SizedBox(
                                      width: 8), // Space between icon and text

                                  SizedBox(
                                      width:
                                          8), // Space between label and value
                                  Expanded(
                                    child: Text(
                                      profileData != null &&
                                              profileData![
                                                      'interestedCourse'] !=
                                                  null
                                          ? profileData!['interestedCourse']
                                          : "Not provided",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: Colors
                                          .red), // Icon for "User Location"
                                  SizedBox(
                                      width: 8), // Space between icon and text

                                  SizedBox(
                                      width:
                                          8), // Space between label and value
                                  Expanded(
                                    child: Text(
                                      profileData != null &&
                                              profileData![
                                                      'userInterestedStateOfCounsellors'] !=
                                                  null &&
                                              profileData![
                                                      'userInterestedStateOfCounsellors']
                                                  .isNotEmpty
                                          ? profileData![
                                                  'userInterestedStateOfCounsellors']
                                              .join(", ")
                                          : "Not provided",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .orange[300], // Green background for the button
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded edges
                            ),
                          ),
                          onPressed: _showUpdateModal, // Edit functionality
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.white, // White text color
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
