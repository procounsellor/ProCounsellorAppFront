import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'CollegeDetailsPage.dart';

class CollegeEntry {
  final String name;
  final String state;
  final String category;
  final String imagePath;

  CollegeEntry({
    required this.name,
    required this.state,
    required this.category,
    required this.imagePath,
  });

  factory CollegeEntry.fromJson(Map<String, dynamic> json) {
    return CollegeEntry(
      name: json['name'],
      state: json['state'],
      category: json['category'],
      imagePath:
          'assets/images/homepage/trending_colleges/${json['name'].toString().toLowerCase().replaceAll(" ", "_")}.png',
    );
  }
}

class CollegesPage extends StatefulWidget {
  final String username;
  const CollegesPage({super.key, required this.username});
  @override
  _CollegesPageState createState() => _CollegesPageState();
}

class _CollegesPageState extends State<CollegesPage> {
  final List<String> categories = [
    "Engineering",
    "Medical",
    "Law",
    "Management",
    "Pharma",
    "Multidisciplinary"
  ];

  String selectedCategory = "Engineering";
  String selectedState = "Tamil Nadu";
  List<CollegeEntry> allColleges = [];
  Set<String> availableStates = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCollegeData();
  }

  Future<void> loadCollegeData() async {
    setState(() => isLoading = true);
    final String response = await rootBundle
        .loadString('assets/data/colleges/college_ranking.json');
    final List<dynamic> data = json.decode(response);
    final entries = data.map((e) => CollegeEntry.fromJson(e)).toList();

    setState(() {
      allColleges = entries;
      availableStates = entries
          .where((e) => e.category == selectedCategory)
          .map((e) => e.state)
          .toSet();

      selectedState = availableStates.isNotEmpty ? availableStates.first : "";

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredColleges = allColleges
        .where(
            (e) => e.category == selectedCategory && e.state == selectedState)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Top Colleges", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Row(
        children: [
          // Left Panel
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 250, 250, 250),
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        selectedState = "";
                        isLoading = true;
                      });
                      loadCollegeData();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage(
                              'assets/images/$category.jpg',
                            ),
                            onBackgroundImageError: (_, __) {},
                            child: Image.asset(
                              'assets/images/$category.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  category[0],
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 18),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Divider(
                            thickness: 1.5,
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Right Panel
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(12),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select State",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedState.isNotEmpty &&
                                  availableStates.contains(selectedState)
                              ? selectedState
                              : (availableStates.isNotEmpty
                                  ? availableStates.first
                                  : null),
                          dropdownColor:
                              Colors.white, // White background for dropdown
                          style: TextStyle(color: Colors.black), // Text style
                          underline: Container(
                              height: 1.5, color: Colors.orange), // Bottom line
                          iconEnabledColor: Colors.orangeAccent, // Orange arrow
                          borderRadius: BorderRadius.circular(8),
                          items: availableStates.map((state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.orange.shade100,
                                        width: 1),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(state),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedState = value;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: filteredColleges.isEmpty
                              ? Center(child: Text("No colleges found."))
                              : SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: filteredColleges
                                        .map((college) => GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        CollegeDetailsPage(
                                                      collegeName: college.name,
                                                      username: widget.username,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: ClipOval(
                                                      child: Image.asset(
                                                        college.imagePath,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Image.asset(
                                                            'assets/images/homepage/trending_colleges/fallback.png',
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    college.name,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
