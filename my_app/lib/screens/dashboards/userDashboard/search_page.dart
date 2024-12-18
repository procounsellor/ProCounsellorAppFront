import 'package:flutter/material.dart';
import 'details_page.dart';

class SearchPage extends StatefulWidget {
  final List<dynamic> liveCounsellors;
  final List<dynamic> topRatedCounsellors;
  final List<String> topNews;
  final String userId;

  SearchPage({
    required this.liveCounsellors,
    required this.topRatedCounsellors,
    required this.topNews,
    required this.userId,
  });

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controllers to manage the search text field
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Function to filter items based on the search query
  List<dynamic> _filterItems(List<dynamic> items) {
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      if (item is String) {
        return item.toLowerCase().contains(_searchQuery.toLowerCase());
      } else if (item is Map) {
        // Check the 'firstName' or 'userName' for counsellors
        return (item['firstName'] ?? item['userName'])
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Counsellors"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0), // Height of the search bar
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              decoration: InputDecoration(
                labelText: "Search...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Display Live Counsellors
            _buildHorizontalList(
                "Live Counsellors", _filterItems(widget.liveCounsellors)),
            SizedBox(height: 20),
            // Display Top Rated Counsellors
            _buildHorizontalList("Top Rated Counsellors",
                _filterItems(widget.topRatedCounsellors)),
            SizedBox(height: 20),
            // Display Top News
            _buildHorizontalList("Top News", _filterItems(widget.topNews),
                isNews: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(String title, List<dynamic> items,
      {bool isNews = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 120, // Fixed height for the list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              if (isNews) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to the DetailsPage for News
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName: items[index],
                          userId: '', // No userId for news
                          counsellorId: '', // No counsellorId for news
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      child: Text(
                        items[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              } else {
                final counsellor = items[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to the DetailsPage for Counsellor
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName:
                              counsellor['firstName'] ?? counsellor['userName'],
                          userId: widget.userId, // Pass the userId if necessary
                          counsellorId:
                              counsellor['userName'] ?? '', // Pass counsellorId
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            counsellor['photoUrl'] ??
                                'https://via.placeholder.com/100',
                          ),
                          radius: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          counsellor['firstName'] ??
                              counsellor['userName'] ??
                              'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
