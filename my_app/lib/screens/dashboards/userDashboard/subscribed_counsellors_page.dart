import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_utils.dart';
import 'details_page.dart'; // Import the DetailsPage

class SubscribedCounsellorsPage extends StatefulWidget {
  final String username;
  final Future<void> Function() onSignOut;

  SubscribedCounsellorsPage({required this.username, required this.onSignOut});

  @override
  _SubscribedCounsellorsPageState createState() =>
      _SubscribedCounsellorsPageState();
}

class _SubscribedCounsellorsPageState extends State<SubscribedCounsellorsPage> {
  List<dynamic> counsellors = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSubscribedCounsellors();
  }

  Future<void> fetchSubscribedCounsellors() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/user/${widget.username}/subscribed-counsellors');

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
          SnackBar(content: Text("Failed to load subscribed counsellors")),
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
        title: Text("Subscribed Counsellors"),
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
                      fillColor: Color(0xFFFFF3E0), // Light orange hue
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
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.75,
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
                          final name =
                              counsellor['firstName']?.toLowerCase() ?? '';
                          return name.contains(searchQuery);
                        }).toList();

                        final counsellor = filteredCounsellors[index];
                        final name = counsellor['firstName'] ?? 'Unknown';
                        final sirName = counsellor['lastName'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            // Navigate to the DetailsPage when tapped
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
                                  onSignOut: widget.onSignOut,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Image.network(
                                    counsellor['photoUrl'] ??
                                        'https://via.placeholder.com/150',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    name + '\n' + sirName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.normal,
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
