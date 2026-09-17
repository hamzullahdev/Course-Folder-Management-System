import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthController {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // 1. LOGIN USER FUNCTION
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['access_token'],
          'role': data['role'],
          // FIXED: Agar server email nahi bhej raha, toh input wala email select ho jayega
          'email': data['email'] ?? (data['user'] != null ? data['user']['email'] : email),
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login Failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable'};
    }
  }

  // 2. LOGOUT USER FUNCTION
  Future<bool> logoutUser(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // Passing bearer token safely
        },
      );

      // DEBUG: Console mai check karne ke liye ke server kya bhej raha hai
      print("========== LOGOUT DEBUG ==========");
      print("Laravel Status Code: ${response.statusCode}");
      print("Laravel Response Body: ${response.body}");
      print("==================================");

      // Laravel standard api logout par 200 ya 204 (No Content) return karta hai
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      print("Logout API Catch Error: $e");
      return false;
    }
  }
}