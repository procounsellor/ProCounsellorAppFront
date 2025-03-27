import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class ExamDetailsPage extends StatefulWidget {
  final String examName;
  final String category;

  const ExamDetailsPage({
    required this.examName,
    required this.category,
    super.key,
  });

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  Map<String, dynamic>? examDetails;
  bool isLoading = true;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    loadExamInfo();
  }

  Future<void> loadExamInfo() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/exams/exam_info.json');
      final List<dynamic> data = json.decode(response);

      final found = data.firstWhere(
        (e) =>
            e['name'].toString().toLowerCase() == widget.examName.toLowerCase(),
        orElse: () => null,
      );

      if (found != null) {
        setState(() {
          examDetails = found['information'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Failed to load exam info: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageAsset =
        'assets/images/homepage/trending_exams/exams_page/${widget.category}/${widget.examName.toLowerCase().replaceAll(' ', '_')}.png';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                        ? 'Bookmarked ${widget.examName}'
                        : 'Removed bookmark',
                  ),
                ),
              );
            },
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'share',
            mini: true,
            tooltip: 'Share',
            backgroundColor: Colors.greenAccent,
            onPressed: () {
              Share.share('Check out ${widget.examName}!');
            },
            child: Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : examDetails == null
                    ? Center(child: Text('No information found.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: AssetImage(imageAsset),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.examName.toUpperCase(),
                              textAlign: TextAlign.left,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[400],
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 20),
                            ...examDetails!.entries.map((entry) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      entry.value.toString(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
          ),

          // ✅ Floating ❓ Button stays properly aligned now
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: 'info',
              mini: true,
              tooltip: 'More Options',
              backgroundColor: Colors.greenAccent,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
