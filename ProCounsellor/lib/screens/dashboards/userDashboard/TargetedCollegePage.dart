import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../services/api_utils.dart';
import '../userDashboard/components/CollegeDetailsPage.dart'; // Update this import path as per your structure

class TargetedCollegePage extends StatefulWidget {
  final String userId;

  const TargetedCollegePage({super.key, required this.userId});

  @override
  State<TargetedCollegePage> createState() => _TargetedCollegePageState();
}

class _TargetedCollegePageState extends State<TargetedCollegePage> {
  List<dynamic> targetedColleges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTargetedColleges();
  }

  Future<void> fetchTargetedColleges() async {
    final url = '${ApiUtils.baseUrl}/api/user/${widget.userId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          targetedColleges = decoded['interestedColleges'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('❌ Error fetching colleges: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildCollegeTile(Map<String, dynamic> college) {
    final String name = college['name'] ?? 'Unknown College';
    final String city = college['city'] ?? '';
    final String state = college['state'] ?? '';
    final String imageUrl = college['imageUrl'] ?? '';
    final String displayLocation = '$city, $state';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollegeDetailsPage(
              collegeName: name,
              username: widget.userId,
            ),
          ),
        );
      },
      child: Column(
        children: [
          ListTile(
            // leading: CircleAvatar(
            //   backgroundImage:
            //       imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            //   backgroundColor: Colors.grey.shade300,
            // ),
            title: Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              displayLocation,
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          Divider(thickness: 0.5, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('TARGETED COLLEGES',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, color: Colors.grey[800])),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : targetedColleges.isEmpty
              ? Center(
                  child: Text(
                    'No targeted colleges yet.',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: targetedColleges.length,
                  itemBuilder: (context, index) {
                    return buildCollegeTile(targetedColleges[index]);
                  },
                ),
    );
  }
}
