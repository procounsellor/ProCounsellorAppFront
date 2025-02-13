import 'package:flutter/material.dart';

class CallOverlayManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static OverlayEntry? _overlayEntry;

  static void showIncomingCall(Map<String, dynamic> callData,
      BuildContext context, VoidCallback onAccept, VoidCallback onDecline) {
    if (_overlayEntry != null) return; // Prevent multiple overlays

    bool isVideoCall = callData['callType'] == 'video';

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideoCall ? Icons.videocam : Icons.call,
                      size: 60,
                      color: isVideoCall ? Colors.blueAccent : Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      isVideoCall
                          ? "Incoming Video Call"
                          : "Incoming Audio Call",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "From: ${callData['callerId']}",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            removeOverlay();
                            onAccept();
                          },
                          child: Text("Accept", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            removeOverlay();
                            onDecline();
                          },
                          child:
                              Text("Decline", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
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
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}