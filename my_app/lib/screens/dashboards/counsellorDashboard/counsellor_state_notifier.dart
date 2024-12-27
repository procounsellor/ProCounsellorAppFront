import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class CounsellorStateNotifier with ChangeNotifier {
  final String counsellor;
  bool _isOnline = false;

  CounsellorStateNotifier(this.counsellor);

  bool get isOnline => _isOnline;

  void setOnline() async {
    if (!_isOnline) {
      _isOnline = true;
      notifyListeners();
      await _postStateToServer("online");
    }
  }

  void setOffline() async {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
      await _postStateToServer("offline");
    }
  }

  Future<void> _postStateToServer(String state) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/counsellor/$counsellor/$state'),
      );
      if (response.statusCode == 200) {
        print("Counsellor state updated to $state.");
      } else {
        print("Failed to update user state to $state: ${response.body}");
      }
    } catch (e) {
      print("Error posting user state to server: $e");
    }
  }
}
