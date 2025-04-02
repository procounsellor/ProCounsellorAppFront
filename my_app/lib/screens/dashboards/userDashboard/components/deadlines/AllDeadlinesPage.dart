import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ApplyPage.dart';

class AllDeadlinesPage extends StatefulWidget {
  final List<Map<String, String>> deadlines;

  const AllDeadlinesPage({super.key, required this.deadlines});

  @override
  State<AllDeadlinesPage> createState() => _AllDeadlinesPageState();
}

class _AllDeadlinesPageState extends State<AllDeadlinesPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.deadlines.where((d) {
      final text = (d['title'] ?? '') + (d['date'] ?? '');
      return text.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Deadlines"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search deadlines...",
                prefixIcon: Icon(Icons.search, color: Colors.deepOrangeAccent),
                filled: true,
                fillColor: Colors.orangeAccent.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => query = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  height: 16,
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            Text(item['date'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info_outline,
                            color: Colors.orangeAccent),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            builder: (_) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'] ?? '',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ApplyGuidePage(
                                            examTitle:
                                                item['title'] ?? 'Application',
                                            videoUrl: item['video'] ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.forward_sharp,
                                        color: Colors.deepOrange),
                                    label: Text(
                                      "Apply",
                                      style: GoogleFonts.outfit(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.support_agent,
                                        color: Colors.deepOrange),
                                    title: Text("Connect to Counsellor",
                                        style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Connecting to counsellor...")),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    ],
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
