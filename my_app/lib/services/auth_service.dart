import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/api/auth';
  // http://10.0.2.2:8080

  static Future<String> signUp(
      String username,
      String firstName,
      String lastName,
      String phoneNumber,
      String email,
      String password,
      String role) async {
    final String endpoint = '$_baseUrl/${role}Signup';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        'role': role
      }),
    );

    final data = jsonDecode(response.body);
    return data['message'];
  }

  static Future<String> signIn(String username, String password) async {
    for (String role in ['user', 'counsellor', 'admin']) {
      final String endpoint = '$_baseUrl/${role}Signin';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userName': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return role;
      }
    }
    return "Invalid credentials or user not found.";
  }
}
