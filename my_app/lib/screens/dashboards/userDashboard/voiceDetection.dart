import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceDetection {
  final RTCPeerConnection peerConnection;
  final Function(bool) onSpeakingChange;
  Timer? _timer;

  VoiceDetection(
      {required this.peerConnection, required this.onSpeakingChange});

  void startListening() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      var stats = await peerConnection.getStats();
      bool isSpeaking = _detectVoiceActivity(stats);
      onSpeakingChange(isSpeaking);
    });
  }

  bool _detectVoiceActivity(List<StatsReport> stats) {
    for (var report in stats) {
      if (report.type == 'ssrc' &&
          report.values.containsKey('audioInputLevel')) {
        double audioLevel =
            double.tryParse(report.values['audioInputLevel'] ?? '0') ?? 0.0;
        return audioLevel > 0.01; // Adjust threshold for sensitivity
      }
    }
    return false;
  }

  void stopListening() {
    _timer?.cancel();
  }
}
