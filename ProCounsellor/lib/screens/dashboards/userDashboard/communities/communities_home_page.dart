import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'community_page.dart';
import 'models/community.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunitiesHomePage extends StatefulWidget {
  const CommunitiesHomePage({Key? key}) : super(key: key);

  @override
  State<CommunitiesHomePage> createState() => _CommunitiesHomePageState();
}

class _CommunitiesHomePageState extends State<CommunitiesHomePage> {
  List<Community> communities = [];
  String selectedTag = 'Explore';

  @override
  void initState() {
    super.initState();
    loadCommunities();
  }

  Future<void> loadCommunities() async {
    final String response =
        await rootBundle.loadString('assets/data/communities/communities.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      communities = data.map((json) => Community.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "COMMUNITIES",
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔖 Tags: My Communities / Explore
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 10),
                // 🔖 Custom-Styled Tags: My Communities / Explore
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: ['My Communities', 'Explore'].map((labelText) {
                      final bool isSelected = selectedTag == labelText;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          label: Text(
                            labelText,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.green,
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // 👈 smaller radius
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedTag = labelText;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 👇 Community List (can later be filtered by selectedTag)
          Expanded(
            child: communities.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: communities.length,
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      return CommunityCard(
                        name: community.name,
                        description: community.description,
                        memberCount: community.members,
                        imagePath: community.image,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityPage(
                                communityId: community.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final String name;
  final String description;
  final int memberCount;
  final String imagePath;
  final VoidCallback onTap;

  const CommunityCard({
    Key? key,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔼 Image Banner with sharp edges
            Image.asset(
              imagePath,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),

            // 🔹 Divider
            const Divider(height: 1, thickness: 0.5, color: Colors.grey),

            // 📄 Text Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$memberCount members',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Optional: Join/leave logic
                      },
                      child: Text(
                        'Join',
                        style: GoogleFonts.outfit(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
