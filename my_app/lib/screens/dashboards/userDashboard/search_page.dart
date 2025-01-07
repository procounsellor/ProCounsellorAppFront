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
  Set<String> _selectedFilters = {};

  List<dynamic> _filterItems(List<dynamic> items) {
    if (_searchQuery.isEmpty) {
      return [];
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
                  right: 8,
                  top: 8,
                  child: Icon(Icons.mic,
                      color: Colors.orange), // Voice Search Icon
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
            if (_searchQuery.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    if ((_selectedFilters.isEmpty ||
                            _selectedFilters.contains("counsellors")) &&
                        _filterItems(widget.liveCounsellors).isNotEmpty)
                      _buildCard("Live Counsellors",
                          _filterItems(widget.liveCounsellors)),
                    if ((_selectedFilters.isEmpty ||
                            _selectedFilters.contains("counsellors")) &&
                        _filterItems(widget.topRatedCounsellors).isNotEmpty)
                      _buildCard("Top Rated Counsellors",
                          _filterItems(widget.topRatedCounsellors)),
                    if ((_selectedFilters.isEmpty ||
                            _selectedFilters.contains("news")) &&
                        _filterItems(widget.topNews).isNotEmpty)
                      _buildCard("Top News", _filterItems(widget.topNews),
                          isNews: true),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/no_results.png', // Add your asset path
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Start typing to see results",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
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

  Widget _buildCard(String title, List<dynamic> items, {bool isNews = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
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
                                counsellor['userName'],
                            userId: widget.userId,
                            counsellorId: counsellor['userName'] ?? '',
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
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
