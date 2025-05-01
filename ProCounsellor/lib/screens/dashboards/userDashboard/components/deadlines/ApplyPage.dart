import 'package:ProCounsellor/screens/dashboards/userDashboard/subscribed_counsellors_page.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplyGuidePage extends StatefulWidget {
  final String examTitle;
  final String videoUrl;
  final String username;

  const ApplyGuidePage(
      {Key? key,
      required this.examTitle,
      required this.videoUrl,
      required this.username})
      : super(key: key);

  @override
  State<ApplyGuidePage> createState() => _ApplyGuidePageState();
}

class _ApplyGuidePageState extends State<ApplyGuidePage> {
  late YoutubePlayerController _controller;
  late YoutubePlayerBuilder _youtubePlayerBuilder;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );
  }

  void _showChecklist() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Application Checklist", style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            "✔ Recent Passport Size Photo",
            "✔ Scanned Signature",
            "✔ ID Proof (Aadhaar/PAN/etc.)",
            "✔ Academic Details (10th/12th)",
            "✔ Valid Email & Mobile Number",
          ]
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(item, style: GoogleFonts.outfit(fontSize: 14)),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.outfit()),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.deepOrange,
        progressColors: const ProgressBarColors(
          playedColor: Colors.deepOrange,
          handleColor: Colors.deepOrangeAccent,
        ),
        bottomActions: [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
          FullScreenButton(),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              "How to Apply",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).size.width * 9 / 16,
                              width: double.infinity,
                              child: player,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "This video explains how to apply for ${widget.examTitle}.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          _buildActionTile(
                            text: 'VIEW CHECKLIST',
                            icon: Icons.chevron_right,
                            onTap: _showChecklist,
                          ),
                          Divider(),
                          _buildActionTile(
                            text: 'PROCEED TO APPLICATION',
                            icon: Icons.chevron_right,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Start your application for ${widget.examTitle}")),
                              );
                            },
                          ),
                          Divider(),
                          _buildActionTile(
                            text: 'CONNECT TO COUNSELLOR',
                            icon: Icons.chevron_right,
                            onTap: () {
                              // Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubscribedCounsellorsPage(
                                    username: widget.username,
                                    onSignOut: () async {},
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
          letterSpacing: 1.0,
        ),
      ),
      trailing: Icon(icon, color: Colors.grey),
    );
  }
}
