import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class MessageNotifierService extends ChangeNotifier {
  final String username;
  final List<String> chatIds;

  final Map<String, StreamSubscription<DatabaseEvent>> _listeners = {};
  final Map<String, bool> _chatHasUnseen = {};

  bool get hasUnseenMessages =>
      _chatHasUnseen.values.any((hasUnseen) => hasUnseen);

  MessageNotifierService({required this.username, required this.chatIds}) {
    _startListening();
  }

  void _startListening() {
    for (String chatId in chatIds) {
      final ref = FirebaseDatabase.instance.ref('chats/$chatId/messages');

      // Initialize
      _chatHasUnseen[chatId] = false;

      // Listen to any message changes
      _listeners['$chatId-added'] = ref.onChildAdded.listen((event) {
        _evaluateChat(chatId, event.snapshot);
      });

      _listeners['$chatId-changed'] = ref.onChildChanged.listen((event) {
        _evaluateChat(chatId, event.snapshot);
      });

      // Also check existing messages on init
      ref.once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          final messages = snapshot.snapshot.value as Map<dynamic, dynamic>;
          for (var entry in messages.entries) {
            final msg = Map<String, dynamic>.from(entry.value);
            final isSeen = msg['isSeen'] ?? true;
            final senderId = msg['senderId'] ?? '';
            if (!isSeen && senderId != username) {
              _chatHasUnseen[chatId] = true;
              notifyListeners();
              return;
            }
          }
        }
        _chatHasUnseen[chatId] = false;
        notifyListeners();
      });
    }
  }

  void _evaluateChat(String chatId, DataSnapshot snapshot) {
    if (!snapshot.exists) return;

    final msg = Map<String, dynamic>.from(snapshot.value as Map);
    final isSeen = msg['isSeen'] ?? true;
    final senderId = msg['senderId'] ?? '';

    final previouslyHadUnseen = _chatHasUnseen[chatId] ?? false;

    if (!isSeen && senderId != username) {
      if (!previouslyHadUnseen) {
        _chatHasUnseen[chatId] = true;
        notifyListeners(); // New unseen message
      }
    } else {
      // Re-check the entire chat to confirm all messages are now seen
      FirebaseDatabase.instance
          .ref('chats/$chatId/messages')
          .once()
          .then((snap) {
        bool stillUnseen = false;
        if (snap.snapshot.exists) {
          final messages = snap.snapshot.value as Map<dynamic, dynamic>;
          for (var entry in messages.entries) {
            final msg = Map<String, dynamic>.from(entry.value);
            final isSeen = msg['isSeen'] ?? true;
            final senderId = msg['senderId'] ?? '';
            if (!isSeen && senderId != username) {
              stillUnseen = true;
              break;
            }
          }
        }

        if (_chatHasUnseen[chatId] != stillUnseen) {
          _chatHasUnseen[chatId] = stillUnseen;
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var sub in _listeners.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
