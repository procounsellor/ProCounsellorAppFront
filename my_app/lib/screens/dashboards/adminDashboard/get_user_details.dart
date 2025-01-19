import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDetailsPage extends StatefulWidget {
  final String userName;

  UserDetailsPage({required this.userName});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/user/${widget.userName}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _userDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Details")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userDetails == null
              ? Center(child: Text("Failed to load user details"))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Username: ${_userDetails!['userName'] ?? 'N/A'}", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Full Name: ${_userDetails!['firstName'] ?? 'N/A'} ${_userDetails!['lastName'] ?? 'N/A'}"),
                      Text("Email: ${_userDetails!['email'] ?? 'N/A'}"),
                      Text("Phone: ${_userDetails!['phoneNumber'] ?? 'N/A'}"),
                      Text("Balance: \$${_userDetails!['balance'] ?? 0.0}"),

                      // Handling nullable lists safely
                      Text("Subscribed Counsellors: ${_userDetails!['subscribedCounsellorIds'] != null && _userDetails!['subscribedCounsellorIds'].isNotEmpty 
                          ? _userDetails!['subscribedCounsellorIds'].join(', ') 
                          : 'No subscriptions'}"),

                      Text("Followed Counsellors: ${_userDetails!['followedCounsellorsIds'] != null && _userDetails!['followedCounsellorsIds'].isNotEmpty 
                          ? _userDetails!['followedCounsellorsIds'].join(', ') 
                          : 'No followed counsellors'}"),

                      Text("Interested Course: ${_userDetails!['interestedCourse'] ?? 'N/A'}"),
                      Text("Interested location of College: ${_userDetails!['userInterestedStateOfCounsellors'] ?? 'N/A'}"),
                      
                      SizedBox(height: 20),
                      _userDetails!['photo'] != null && _userDetails!['photo'].isNotEmpty
                          ? Image.network(_userDetails!['photo'])
                          : Text("No profile photo available"),
                    ],
                  ),
                ),
    );
  }
}
