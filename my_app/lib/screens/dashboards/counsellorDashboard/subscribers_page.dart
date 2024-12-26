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
  List<dynamic> filteredSubscribers = [];
  bool isLoading = true;

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
          subscribers = json.decode(response.body);
          filteredSubscribers = subscribers; // Initially, show all subscribers
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

  void filterSubscribers(String query) {
    setState(() {
      filteredSubscribers = subscribers
          .where((subscriber) =>
              "${subscriber['firstName']} ${subscriber['lastName']}"
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Subscribers"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search Subscribers",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filterSubscribers,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSubscribers.length,
                    itemBuilder: (context, index) {
                      final subscriber = filteredSubscribers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            subscriber['photo'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                            "${subscriber['firstName']} ${subscriber['lastName']}"),
                        subtitle: Text("Email: ${subscriber['email']}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientDetailsPage(
                                client: subscriber,
                                counsellorId: widget.counsellorId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
