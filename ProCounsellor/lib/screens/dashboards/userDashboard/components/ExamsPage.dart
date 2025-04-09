import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'ExamDetailsPage.dart';

class ExamEntry {
  final String name;
  final String level;
  final String description;
  final String? organization;

  ExamEntry({
    required this.name,
    required this.level,
    required this.description,
    this.organization,
  });

  factory ExamEntry.fromJson(Map<String, dynamic> json) {
    return ExamEntry(
      name: json['name'],
      level: json['level'],
      description: json['description'],
      organization: json['organization'] ?? '',
    );
  }
}

class ExamsPage extends StatefulWidget {
  @override
  _ExamsPageState createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  final List<String> categories = [
    "Engineering",
    "Medical",
    "Law",
    "Management",
    "Architecture"
  ];

  final Map<String, String> categoryImages = {
    "Engineering": "assets/images/Engineering.jpg",
    "Medical": "assets/images/Medical.jpg",
    "Law": "assets/images/Law.jpg",
    "Management": "assets/images/Management.jpg",
    "Architecture": "assets/images/Architecture.jpg",
  };

  final Map<String, String> countryMap = {
    "india": "India",
    "usa": "USA",
    "uk": "UK",
    "canada": "Canada",
    "australia": "Australia",
    "germany": "Germany"
  };

  String selectedCategory = "Engineering";
  String selectedCountry = "india";

  Map<String, List<ExamEntry>> parsedExamData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExamData();
  }

  Future<void> loadExamData() async {
    try {
      final String response = await rootBundle.loadString(
          'assets/data/exams/${selectedCategory.toLowerCase()}_exams.json');
      final Map<String, dynamic> jsonData = json.decode(response);

      // Parse all country-wise exams (India + Abroad)
      final Map<String, dynamic> abroadMap = jsonData["Abroad"];
      final List<dynamic> indiaList = jsonData["India"];

      parsedExamData = {
        "india": indiaList
            .map((item) => ExamEntry.fromJson(item as Map<String, dynamic>))
            .toList()
      };

      for (var country in abroadMap.keys) {
        parsedExamData[country.toLowerCase()] = (abroadMap[country] as List)
            .map((e) => ExamEntry.fromJson(e))
            .toList();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading exam data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Exams", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Row(
        children: [
          // Left side (Categories)
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 250, 250, 250), // Light orange hue
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                        selectedCountry = "india";
                        isLoading = true;
                      });
                      loadExamData();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              categoryImages[category]!,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            category,
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

          // Right side (Content)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(12),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : parsedExamData.containsKey(selectedCountry)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Select Country",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: parsedExamData.keys.map((countryKey) {
                                  final isActive =
                                      selectedCountry == countryKey;
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(countryMap[countryKey] ??
                                          countryKey.toUpperCase()),
                                      selected: isActive,
                                      onSelected: (_) {
                                        setState(() {
                                          selectedCountry = countryKey;
                                        });
                                      },
                                      selectedColor: Colors.orange.shade200,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 12),
                            Expanded(
                              child: parsedExamData[selectedCountry] == null
                                  ? Center(child: Text("No data found."))
                                  : SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: parsedExamData[
                                                selectedCountry]!
                                            .map((exam) => GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ExamDetailsPage(
                                                                examName:
                                                                    exam.name,
                                                                category:
                                                                    selectedCategory),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                            'assets/images/homepage/trending_exams/exams_page/$selectedCategory/${exam.name.toLowerCase().replaceAll(" ", "_")}.png',
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context,
                                                                    error,
                                                                    stackTrace) =>
                                                                Container(
                                                              color: Colors
                                                                  .orange
                                                                  .shade100,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Icon(
                                                                  Icons.school,
                                                                  size: 30,
                                                                  color: Colors
                                                                      .deepOrangeAccent),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        exam.name,
                                                        textAlign:
                                                            TextAlign.center,
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
                        )
                      : Center(
                          child:
                              Text("No data available for $selectedCategory"),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
