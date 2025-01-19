import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CounsellorDetailsPage extends StatefulWidget {
  final String userName;

  CounsellorDetailsPage({required this.userName});

  @override
  _CounsellorDetailsPageState createState() => _CounsellorDetailsPageState();
}

class _CounsellorDetailsPageState extends State<CounsellorDetailsPage> {
  Map<String, dynamic>? _counsellorDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounsellorDetails();
  }

  Future<void> fetchCounsellorDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/counsellor/${widget.userName}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _counsellorDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load counsellor details');
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
      appBar: AppBar(title: Text("Counsellor Details")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _counsellorDetails == null
              ? Center(child: Text("Failed to load counsellor details"))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Username: ${_counsellorDetails!['userName'] ?? 'N/A'}", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Full Name: ${_counsellorDetails!['firstName'] ?? 'N/A'} ${_counsellorDetails!['lastName'] ?? 'N/A'}"),
                      Text("Email: ${_counsellorDetails!['email'] ?? 'N/A'}"),
                      Text("Phone: ${_counsellorDetails!['phoneNumber'] ?? 'N/A'}"),

                      // Handling nullable lists safely
                      Text("Clients: ${_counsellorDetails!['clientIds'] != null && _counsellorDetails!['clientIds'].isNotEmpty 
                          ? _counsellorDetails!['clientIds'].join(', ') 
                          : 'No clients'}"),

                      Text("Followers: ${_counsellorDetails!['followerIds'] != null && _counsellorDetails!['followerIds'].isNotEmpty 
                          ? _counsellorDetails!['followerIds'].join(', ') 
                          : 'No followers'}"),

                      Text("Expertise: ${_counsellorDetails!['expertise'] ?? 'N/A'}"),
                      Text("Location of Counsellor: ${_counsellorDetails!['stateOfCounsellor'] ?? 'N/A'}"),
                      
                      SizedBox(height: 20),
                      _counsellorDetails!['photoUrl'] != null && _counsellorDetails!['photoUrl'].isNotEmpty
                          ? Image.network(_counsellorDetails!['photoUrl'])
                          : Text("No profile photo available"),
                    ],
                  ),
                ),
    );
  }
}
