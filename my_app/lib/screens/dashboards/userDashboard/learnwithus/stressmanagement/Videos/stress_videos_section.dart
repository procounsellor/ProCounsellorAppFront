import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class StressVideosSection extends StatefulWidget {
  const StressVideosSection({super.key});

  @override
  State<StressVideosSection> createState() => _StressVideosSectionState();
}

class _StressVideosSectionState extends State<StressVideosSection> {
  List<Map<String, dynamic>> videos = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    final String jsonString = await rootBundle
        .loadString('assets/data/learnwithus/video/stress_videos.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      videos = jsonData
          .map((item) => {
                "name": item["name"] as String,
                "videoId": YoutubePlayer.convertUrlToId(item["link"]) ?? ""
              })
          .where((video) => video["videoId"] != "")
          .toList();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Videos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: videos.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final controller = YoutubePlayerController(
                            initialVideoId: video["videoId"],
                            flags: YoutubePlayerFlags(
                              autoPlay: false,
                              mute: false,
                            ),
                          );

                          return Container(
                            width: 250,
                            margin: EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                YoutubePlayer(
                                  controller: controller,
                                  showVideoProgressIndicator: true,
                                  width: double.infinity,
                                  progressIndicatorColor: Colors.orange,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  video["name"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
