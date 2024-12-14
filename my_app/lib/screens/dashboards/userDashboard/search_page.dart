import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final List<String> list1;
  final List<String> list2;
  final List<String> list3;

  SearchPage({
    required this.list1,
    required this.list2,
    required this.list3,
  });

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _combinedList;
  late List<String> _filteredList;

  @override
  void initState() {
    super.initState();
    // Combine all lists into a single list
    _combinedList = [...widget.list1, ...widget.list2, ...widget.list3];
    _filteredList = List.from(_combinedList); // Initialize filtered list
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredList = _combinedList
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            SizedBox(height: 20),
            // Results
            Expanded(
              child: _filteredList.isEmpty
                  ? Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_filteredList[index]),
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
