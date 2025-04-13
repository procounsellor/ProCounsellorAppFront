import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'models/posts.dart';

class CommunityPage extends StatelessWidget {
  final String communityId;

  const CommunityPage({Key? key, required this.communityId}) : super(key: key);

  // Dynamically builds mock data for now
  Map<String, dynamic> get communityData {
    String displayName = communityId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return {
      'name': displayName,
      'members': 12800,
      'image': 'assets/images/community/$communityId.jpg',
      'description':
          'Welcome to $displayName — discuss ideas, share updates, and connect.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final String name = communityData['name'];
    final int members = communityData['members'];
    final String image = communityData['image'];
    final String description = communityData['description'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 160,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      Container(color: Colors.black.withOpacity(0.3)),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$members members',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: null, // moved tabbar to persistent header below
              ),

              // 👇 Persistent Join Button + TabBar in its own pinned header
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarWithJoinDelegate(
                  tabBar: const TabBar(
                    indicatorColor: Colors.green,
                    labelColor: Colors.black,
                    tabs: [
                      Tab(text: "What's Goin' On"),
                      Tab(text: 'About'),
                    ],
                  ),
                  joinButton: TextButton(
                    onPressed: () {
                      // TODO: handle join
                    },
                    child: Text(
                      'Join',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              PostsTab(communityId: communityId),
              AboutTab(communityId: communityId),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarWithJoinDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Widget joinButton;

  _TabBarWithJoinDelegate({
    required this.tabBar,
    required this.joinButton,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(child: tabBar),
          joinButton,
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56; // Increase to fit your row properly

  @override
  double get minExtent =>
      56; // Match this with maxExtent if it's not collapsible

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class PostsTab extends StatefulWidget {
  final String communityId;

  const PostsTab({Key? key, required this.communityId}) : super(key: key);

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final String data = await rootBundle
        .loadString('assets/data/communities/community_posts.json');
    final List<dynamic> jsonList = json.decode(data);
    final List<Post> allPosts =
        jsonList.map((json) => Post.fromJson(json)).toList();
    final filtered = allPosts
        .where((post) => post.communityId == widget.communityId)
        .toList();

    setState(() {
      posts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Author + Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    post.author,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${post.timestamp.toLocal()}'.split(' ')[0],
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Post Content
              if (post.type == 'text')
                Text(
                  post.content,
                  style: GoogleFonts.outfit(fontSize: 15),
                ),
              if (post.type == 'media')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.mediaUrl != null)
                      Image.asset(
                        post.mediaUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    const SizedBox(height: 8),
                    if (post.caption != null)
                      Text(
                        post.caption!,
                        style: GoogleFonts.outfit(fontSize: 15),
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              // Likes and Comments Stats Row
              Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '24', // mock like count
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${post.comments.length}',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Comments
              ...post.comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.reply, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: '${c.author}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: c.content),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class AboutTab extends StatelessWidget {
  final String communityId;

  const AboutTab({Key? key, required this.communityId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'About this community...\n\n(Description, rules, and contact info here)',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
