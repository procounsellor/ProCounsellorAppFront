import 'package:ProCounsellor/screens/dashboards/userDashboard/components/CollegeDetailsPage.dart';
import 'package:flutter/material.dart';
import 'details_page.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SearchPage extends StatefulWidget {
  final List<dynamic> topRatedCounsellors;
  final List<String> topNews;
  final String userId;
  final Future<void> Function() onSignOut;

  SearchPage(
      {required this.topRatedCounsellors,
      required this.topNews,
      required this.userId,
      required this.onSignOut});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedFilters = {};
  List<dynamic> collegeList = [];
  bool isCollegeDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollegeData();
  }

  Future<void> _loadCollegeData() async {
    final String jsonString = await rootBundle
        .loadString('assets/data/colleges/college_ranking.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      collegeList = jsonData;
      isCollegeDataLoading = false;
    });
  }

  List<dynamic> _filterItems(List<dynamic> items) {
    if (_searchQuery.isEmpty) return [];

    return items.where((item) {
      final query = _searchQuery.toLowerCase();

      if (item is String) {
        return item.toLowerCase().contains(query);
      } else if (item is Map) {
        final buffer = StringBuffer();

        // Counsellor
        buffer.write('${item['firstName'] ?? ''} ');
        buffer.write('${item['userName'] ?? ''} ');

        // College
        buffer.write('${item['name'] ?? ''} ');
        buffer.write('${item['city'] ?? ''} ');
        buffer.write('${item['state'] ?? ''} ');
        buffer.write('${item['rank']?.toString() ?? ''} ');

        buffer.write('${item['category'] ?? ''} ');

        // Description (overview)
        if (item['description'] is Map &&
            item['description']['overview'] != null) {
          buffer.write(item['description']['overview']);
        }

        return buffer.toString().toLowerCase().contains(query);
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = (_filterItems(widget.topRatedCounsellors).isNotEmpty ||
        _filterItems(widget.topNews).isNotEmpty ||
        _filterItems(collegeList).isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.search, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              "Search",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Stack(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                    hintText: "Search...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFFFF3E0),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 14,
                  child: Icon(Icons.mic,
                      color: Colors.orange), // Adjusted Voice Search Icon
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterTag("counsellors"),
                _buildFilterTag("news"),
                _buildFilterTag("colleges"),
              ],
            ),
            SizedBox(height: 20),
            if (_searchQuery.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        "https://media.giphy.com/media/AS1QYqISiXDiwLtPg3/giphy.gif",
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Start typing to search",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: hasResults
                    ? ListView(
                        children: [
                          if ((_selectedFilters.isEmpty ||
                                  _selectedFilters.contains("counsellors")) &&
                              _filterItems(widget.topRatedCounsellors)
                                  .isNotEmpty)
                            _buildList(
                                _filterItems(widget.topRatedCounsellors)),
                          if ((_selectedFilters.isEmpty ||
                                  _selectedFilters.contains("news")) &&
                              _filterItems(widget.topNews).isNotEmpty)
                            _buildList(_filterItems(widget.topNews),
                                isNews: true),
                          if (!isCollegeDataLoading &&
                              (_selectedFilters.isEmpty ||
                                  _selectedFilters.contains("colleges")) &&
                              _filterItems(collegeList).isNotEmpty)
                            _buildCollegeList(_filterItems(collegeList)),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.5,
                              child: Image.asset(
                                'assets/images/no_results.png',
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 16),
                            Transform.translate(
                              offset: Offset(-10, -20),
                              child: Text(
                                "No results found",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTag(String tag) {
    final isActive = _selectedFilters.contains(tag);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _selectedFilters.remove(tag);
          } else {
            _selectedFilters.add(tag);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange[100] : Color(0xffeeeeee),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.orange : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, {bool isNews = false}) {
    return SizedBox(
      height: 160,
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
                      userId: widget.userId,
                      counsellorId: '',
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              },
              child: Container(
                width: 120,
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    items[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      itemName:
                          counsellor['firstName'] ?? counsellor['userName'],
                      userId: widget.userId,
                      counsellorId: counsellor['userName'] ?? '',
                      onSignOut: widget.onSignOut,
                    ),
                  ),
                );
              },
              child: Container(
                width: 120,
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        counsellor['photoUrl'] ??
                            'https://via.placeholder.com/150/0000FF/808080?Text=PAKAINFO.com',
                      ),
                      radius: 30,
                    ),
                    SizedBox(height: 8),
                    Text(
                      counsellor['firstName'] ??
                          counsellor['userName'] ??
                          'Unknown',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCollegeList(List<dynamic> colleges) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colleges.length,
        itemBuilder: (context, index) {
          final college = colleges[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollegeDetailsPage(
                      collegeName: college["name"], username: widget.userId),
                ),
              );
            },
            child: Container(
              width: 180,
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(college['name'] ?? '',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 8),
                  Text("${college['city']}, ${college['state']}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  SizedBox(height: 8),
                  Text("Rank: ${college['rank']}",
                      style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
