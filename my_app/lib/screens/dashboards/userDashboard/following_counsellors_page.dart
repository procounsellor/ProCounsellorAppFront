import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_page.dart'; // Import the DetailsPage

class FollowingCounsellorsPage extends StatefulWidget {
  final String username;

  FollowingCounsellorsPage({required this.username});

  @override
  _FollowingCounsellorsPageState createState() =>
      _FollowingCounsellorsPageState();
}

class _FollowingCounsellorsPageState extends State<FollowingCounsellorsPage> {
  List<dynamic> counsellors = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFollowedCounsellors();
  }

  Future<void> fetchFollowedCounsellors() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.username}/followed-counsellors');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          counsellors = json.decode(response.body) ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load followed counsellors")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Followed Counsellors"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      labelStyle: TextStyle(color: Colors.orange),
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      fillColor: Color(0xFFFFF3E0),
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      itemCount: counsellors
                          .where((counsellor) {
                            final name =
                                counsellor['firstName']?.toLowerCase() ?? '';
                            return name.contains(searchQuery);
                          })
                          .toList()
                          .length,
                      itemBuilder: (context, index) {
                        final filteredCounsellors =
                            counsellors.where((counsellor) {
                          final name = counsellor['firstName']?.toLowerCase() +
                                  " " +
                                  counsellor['lastName']?.toLowerCase() ??
                              '';
                          return name.contains(searchQuery);
                        }).toList();

                        final counsellor = filteredCounsellors[index];
                        final name = counsellor['firstName'] +
                                " " +
                                counsellor['lastName']?.toLowerCase() ??
                            'Unknown';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsPage(
                                  itemName: counsellor['firstName'] ??
                                      counsellor['userName'],
                                  userId: widget.username,
                                  counsellorId: counsellor['userName'] ?? '',
                                  isNews: false,
                                  counsellor: counsellor,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    counsellor['photoUrl'] ??
                                        'https://via.placeholder.com/150/0000FF/808080?Text=PAKAINFO.com',
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
