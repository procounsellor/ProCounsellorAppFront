import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplyGuidePage extends StatefulWidget {
  final String examTitle;
  final String videoUrl;

  const ApplyGuidePage({
    Key? key,
    required this.examTitle,
    required this.videoUrl,
  }) : super(key: key);

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
          appBar: AppBar(),
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
                          OutlinedButton.icon(
                            onPressed: _showChecklist,
                            icon: Icon(Icons.checklist_rounded,
                                color: Colors.green),
                            label: Text(
                              "View Checklist",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.greenAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Start your application for ${widget.examTitle}"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text("Proceed to Application"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Connecting to counsellor..."),
                                ),
                              );
                            },
                            icon: Icon(Icons.support_agent,
                                color: Colors.deepOrange),
                            label: Text(
                              "Connect to Counsellor",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: Colors.deepOrange,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepOrange),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
}
