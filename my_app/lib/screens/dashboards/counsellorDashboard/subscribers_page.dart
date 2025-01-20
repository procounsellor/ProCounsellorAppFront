import 'package:flutter/material.dart';
import 'client_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubscribersPage extends StatefulWidget {
  final String counsellorId;

  SubscribersPage({required this.counsellorId});

  @override
  _SubscribersPageState createState() => _SubscribersPageState();
}

class _SubscribersPageState extends State<SubscribersPage> {
  List<dynamic> subscribers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSubscribers();
  }

  Future<void> fetchSubscribers() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          subscribers = json.decode(response.body) ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch subscribers")),
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
        title: Text("Subscribers"),
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
                      labelText: 'Search Subscribers',
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
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: subscribers
                          .where((subscriber) {
                            final name =
                                "${subscriber['firstName']} ${subscriber['lastName']}"
                                    .toLowerCase();
                            return name.contains(searchQuery);
                          })
                          .toList()
                          .length,
                      itemBuilder: (context, index) {
                        final filteredSubscribers =
                            subscribers.where((subscriber) {
                          final name =
                              "${subscriber['firstName']} ${subscriber['lastName']}"
                                  .toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                        final subscriber = filteredSubscribers[index];
                        final name =
                            "${subscriber['firstName']} ${subscriber['lastName']}";

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientDetailsPage(
                                  client: subscriber,
                                  counsellorId: widget.counsellorId,
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
                                    subscriber['photo'] ??
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
                                    name,
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
