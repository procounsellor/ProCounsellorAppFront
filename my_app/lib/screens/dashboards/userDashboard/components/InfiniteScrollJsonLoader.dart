import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class InfiniteScrollJsonLoader extends StatefulWidget {
  @override
  _InfiniteScrollJsonLoaderState createState() =>
      _InfiniteScrollJsonLoaderState();
}

class _InfiniteScrollJsonLoaderState extends State<InfiniteScrollJsonLoader> {
  List<Map<String, dynamic>> _loadedData = [];
  List<String> _jsonFiles = [
    'assets/data/allAgriculture.json',
    'assets/data/architecture_participated.json',
    'assets/data/architecture_ranking.json',
    'assets/data/college_participated.json',
    'assets/data/college_ranking.json',
    // Add more filenames here
  ];
  int _currentFileIndex = 0;
  bool _isLoading = false;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNextJsonFile(); // Load first JSON file initially
    _scrollController.addListener(_onScroll);
  }

  /// **Handles Scroll Event & Loads More Data**
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadNextJsonFile();
    }
  }

  /// **Loads Next JSON File Dynamically**
  Future<void> _loadNextJsonFile() async {
    if (_isLoading || _currentFileIndex >= _jsonFiles.length) return;

    setState(() => _isLoading = true);

    try {
      String jsonString =
          await rootBundle.loadString(_jsonFiles[_currentFileIndex]);
      List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _loadedData
            .addAll(jsonData.map((e) => Map<String, dynamic>.from(e)).toList());
        _currentFileIndex++;
      });
    } catch (e) {
      print("❌ Error loading JSON file: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _loadedData.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _loadedData.length) {
            return ListTile(
              title: Text(_loadedData[index]["Name"] ?? "No Title"),
              subtitle: Text(_loadedData[index]["State"] ?? "No Description"),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
