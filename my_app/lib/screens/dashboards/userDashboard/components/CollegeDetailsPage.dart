import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class CollegeDetailsPage extends StatefulWidget {
  final String collegeName;

  CollegeDetailsPage({required this.collegeName});

  @override
  _CollegeDetailsPageState createState() => _CollegeDetailsPageState();
}

class _CollegeDetailsPageState extends State<CollegeDetailsPage> {
  Map<String, dynamic>? collegeData;
  String selectedTag = "Overview";
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    loadCollegeData();
  }

  Future<void> loadCollegeData() async {
    final String jsonString = await rootBundle
        .loadString('assets/data/colleges/college_ranking.json');
    final List<dynamic> data = json.decode(jsonString);
    final matchedCollege = data.firstWhere(
      (college) =>
          college['name'].toString().toLowerCase() ==
          widget.collegeName.toLowerCase(),
      orElse: () => null,
    );
    if (matchedCollege != null) {
      setState(() {
        collegeData = matchedCollege;
      });
    }
  }

  List<String> tags = [
    "Overview",
    "Academics",
    "Infrastructure",
    "Research",
    "Placements",
    "Campus Life",
    "Alumni",
    "Reputation",
  ];

  Widget _buildModalOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(label,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget buildSection() {
    final d = collegeData!['description'];
    switch (selectedTag) {
      case "Academics":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText(
                "Programs Offered: ${d['academics']['programs_offered'].join(", ")}"),
            sectionText(
                "Specializations: ${d['academics']['specializations'].join(", ")}"),
            sectionText(
                "Global Collaborations: ${d['academics']['global_collaborations'].join(", ")}"),
          ],
        );
      case "Infrastructure":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText("Campus Size: ${d['infrastructure']['campus_size']}"),
            sectionText("Library: ${d['infrastructure']['library']}"),
            sectionText(
                "Research Labs: ${d['infrastructure']['research_labs']}"),
          ],
        );
      case "Research":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText(
                "Focus Areas: ${d['research']['focus_areas'].join(", ")}"),
            sectionText(
                "Startup Ecosystem: ${d['research']['startup_ecosystem']}"),
          ],
        );
      case "Placements":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText(
                "Top Recruiters: ${d['placements']['top_recruiters'].join(", ")}"),
            sectionText(
                "Average Package: ${d['placements']['average_package']}"),
            sectionText(
                "Highest Package (Domestic): ${d['placements']['highest_package']['domestic']}"),
            sectionText(
                "Highest Package (International): ${d['placements']['highest_package']['international']}"),
          ],
        );
      case "Campus Life":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText("Student Clubs: ${d['campus_life']['student_clubs']}"),
            sectionText(
                "Cultural Fest: ${d['campus_life']['festivals']['cultural_fest']}"),
            sectionText(
                "Technical Fest: ${d['campus_life']['festivals']['technical_fest']}"),
          ],
        );
      case "Alumni":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionText("${d['alumni']['notable_alumni'].join(", ")}"),
            sectionText("Entrepreneurship: ${d['alumni']['entrepreneurship']}"),
          ],
        );
      case "Reputation":
        return sectionText(d['reputation']);
      default:
        return sectionText(d['overview']);
    }
  }

  Widget sectionText(String text) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Text(text, style: GoogleFonts.outfit(fontSize: 14)),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (collegeData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.collegeName)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final imagePath =
        'assets/images/homepage/trending_colleges/${widget.collegeName.toLowerCase().replaceAll(' ', '_')}.png';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          imagePath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/homepage/trending_colleges/fallback.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            );
                          },
                        )),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.collegeName.toUpperCase(),
                        style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tags
                        .map((tag) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(tag, style: GoogleFonts.outfit()),
                                selected: selectedTag == tag,
                                onSelected: (_) =>
                                    setState(() => selectedTag = tag),
                                selectedColor: Colors.deepOrangeAccent,
                                labelStyle: GoogleFonts.outfit(
                                    color: selectedTag == tag
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(child: SingleChildScrollView(child: buildSection())),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Admission process coming soon!')),
                    );
                  },
                  child: Text('Want Admission?',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'compare',
            mini: true,
            tooltip: 'Compare',
            backgroundColor: Colors.greenAccent,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compare feature coming soon!')),
              );
            },
            child: Icon(Icons.compare_arrows),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'bookmark',
            mini: true,
            tooltip: 'Bookmark',
            backgroundColor: Colors.greenAccent,
            onPressed: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBookmarked
                        ? 'Bookmarked ${widget.collegeName}'
                        : 'Removed bookmark',
                  ),
                ),
              );
            },
            child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'share',
            mini: true,
            tooltip: 'Share',
            backgroundColor: Colors.greenAccent,
            onPressed: () {
              Share.share('Check out ${widget.collegeName}!');
            },
            child: Icon(Icons.share),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'info',
            mini: true,
            tooltip: 'More Options',
            backgroundColor: Colors.greenAccent,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalOption(
                        icon: Icons.send,
                        label: 'Apply',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Apply clicked')),
                          );
                        },
                      ),
                      _buildModalOption(
                        icon: Icons.school,
                        label: 'Practise',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Practise clicked')),
                          );
                        },
                      ),
                      _buildModalOption(
                        icon: Icons.support_agent,
                        label: 'Connect to Counsellor',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Connecting to counsellor...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
