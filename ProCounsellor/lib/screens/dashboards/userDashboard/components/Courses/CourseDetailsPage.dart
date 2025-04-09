import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseDetailsPage extends StatelessWidget {
  final String courseName;
  final Map<String, dynamic> courseData;

  CourseDetailsPage({
    required this.courseName,
    required this.courseData,
  });

  Widget buildTag(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildSection(String title, dynamic content) {
    if (content is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTag(title),
          ...content.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text("• $item", style: contentStyle),
              )),
          SizedBox(height: 12),
        ],
      );
    } else if (content is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTag(title),
          ...content.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child:
                    Text("• ${entry.key}: ${entry.value}", style: contentStyle),
              )),
          SizedBox(height: 12),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTag(title),
          SizedBox(height: 4),
          Text(content.toString(), style: contentStyle),
          SizedBox(height: 12),
        ],
      );
    }
  }

  final contentStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    final imagePath =
        'assets/images/homepage/trending_courses/${courseName.toLowerCase().replaceAll(" ", "_")}.png';

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName, style: GoogleFonts.outfit(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported, size: 100),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(courseName.toUpperCase(),
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            SizedBox(height: 16),
            ...courseData.entries
                .map((entry) => buildSection(entry.key, entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }
}
