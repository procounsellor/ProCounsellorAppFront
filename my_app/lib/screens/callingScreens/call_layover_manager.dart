import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CallOverlayManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static OverlayEntry? _overlayEntry;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void showIncomingCall(
      Map<String, dynamic> callData,
      BuildContext context,
      VoidCallback onAccept,
      VoidCallback onDecline) async {
    if (_overlayEntry != null) return;

    bool isVideoCall = callData['callType'] == 'video';

    // Start playing ringtone
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/ringer.mp3'));

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Positioned(
            top: 30,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideoCall ? Icons.videocam : Icons.call,
                          size: 28,
                          color: isVideoCall ? Colors.blueAccent : Colors.green,
                        ),
                        SizedBox(height: 4),
                        Text(
                          isVideoCall ? 'Video Call' : 'Audio Call',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        "${callData['callerId']}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            removeOverlay();
                            onAccept();
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.green,
                            child:
                                Icon(Icons.call, color: Colors.white, size: 18),
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            removeOverlay();
                            onDecline();
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.call_end,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    navigatorKey.currentState?.overlay?.insert(_overlayEntry!);
  }

  static void removeOverlay() {
    _audioPlayer.stop();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
