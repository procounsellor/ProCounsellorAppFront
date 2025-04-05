import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'CourseDetailsPage.dart';
import '../../headersText/no_data_placeholder.dart';

class CourseEntry {
  final String name;
  final String category;
  final Map<String, dynamic> description;

  CourseEntry({
    required this.name,
    required this.category,
    required this.description,
  });

  factory CourseEntry.fromJson(Map<String, dynamic> json) {
    return CourseEntry(
      name: json['name'],
      category: json['category'],
      description: json['description'],
    );
  }
}

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<String> categories = [];
  String selectedCategory = "";
  List<CourseEntry> allCourses = [];
  bool isLoading = true;
  String searchQuery = "";
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadCourseData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> loadCourseData() async {
    setState(() => isLoading = true);
    final String response = await rootBundle
        .loadString('assets/data/courses/trending-courses.json');
    final List<dynamic> data = json.decode(response);
    final entries = data.map((e) => CourseEntry.fromJson(e)).toList();

    final cats = entries.map((e) => e.category).toSet().toList();

    setState(() {
      allCourses = entries;
      categories = cats;
      selectedCategory = cats.isNotEmpty ? cats[0] : "";
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (CourseEntry == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        body: const NoDataPlaceholder(),
      );
    }
    final filteredCourses = allCourses
        .where((e) =>
            e.category == selectedCategory &&
            e.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Top Courses", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Row(
        children: [
          // Left Panel - Categories
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 245, 245, 245),
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        searchQuery = "";
                      });
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
                                      color: Colors.blueAccent, fontSize: 18),
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
                                ? Colors.blueAccent
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

          // Right Panel - Course List
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
                        Text("Courses in $selectedCategory",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        FocusScope(
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {}),
                            child: TextField(
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: "Search courses...",
                                prefixIcon: Icon(Icons.search,
                                    color: _focusNode.hasFocus
                                        ? Colors.orangeAccent
                                        : Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.orangeAccent),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: filteredCourses.isEmpty
                              ? Center(child: Text("No courses found."))
                              : ListView.builder(
                                  itemCount: filteredCourses.length,
                                  itemBuilder: (context, index) {
                                    final course = filteredCourses[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: AssetImage(
                                            'assets/images/homepage/trending_courses/${course.name.toLowerCase().replaceAll(" ", "_")}.png'),
                                        onBackgroundImageError:
                                            (error, stackTrace) {},
                                        child: Image.asset(
                                          'assets/images/homepage/trending_courses/${course.name.toLowerCase().replaceAll(" ", "_")}.png',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Text(
                                              course.name[0],
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            );
                                          },
                                        ),
                                      ),
                                      title: Text(course.name),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CourseDetailsPage(
                                                courseName: course.name,
                                                courseData: course.description),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        )
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }
}
