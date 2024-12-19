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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _filterItems(List<dynamic> items) {
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      if (item is String) {
        return item.toLowerCase().contains(_searchQuery.toLowerCase());
      } else if (item is Map) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName: items[index],
                          userId: widget.userId, // Pass the userId
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemName: counsellor['firstName'] ??
                              counsellor[
                                  'userName'], // Pass the counsellor's name
                          userId: widget.userId, // Pass the userId
                          counsellorId: counsellor['userName'] ??
                              '', // Pass the counsellorId
                          isNews:
                              false, // This is a counsellor, so isNews is false
                          counsellor:
                              counsellor, // Pass the full counsellor object
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
                                'https://via.placeholder.com/150/0000FF/808080 ?Text=PAKAINFO.com',
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
