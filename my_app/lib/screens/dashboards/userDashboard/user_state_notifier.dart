import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class UserStateNotifier with ChangeNotifier {
  final String userName;
  bool _isOnline = false;

  UserStateNotifier(this.userName);

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
        Uri.parse('http://localhost:8080/api/user/$userName/$state'),
      );
      if (response.statusCode == 200) {
        print("User state updated to $state.");
      } else {
        print("Failed to update user state to $state: ${response.body}");
      }
    } catch (e) {
      print("Error posting user state to server: $e");
    }
  }
}
