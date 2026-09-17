import 'dart:convert';
import 'package:http/http.dart' as http;

class ProgramController {
  // Base server domain path
  final String baseServerUrl = "http://127.0.0.1:8000/api/admin";

  Future<List<dynamic>> fetchPrograms(String token) async {
    try {
      final response = await http.get(
          Uri.parse('$baseServerUrl/program'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          }
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return decoded['data'] ?? [];
      } else {
        print("Programs Fetch Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception in fetchPrograms: $e");
    }
    return [];
  }

  Future<List<dynamic>> fetchDepartments(String token) async {
    try {
      final response = await http.get(
          Uri.parse('$baseServerUrl/department'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          }
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        // Explicit cast ke sath list return karein taake dropdown render crash na ho
        return List<dynamic>.from(decoded['data'] ?? []);
      } else {
        print("Departments Fetch Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception in fetchDepartments: $e");
    }
    return [];
  }

  Future<bool> addProgram(String name, int deptId, String token) async {
    try {
      print("Sending Data -> Name: $name, DeptId: $deptId"); // Debugging line

      final response = await http.post(
        Uri.parse('$baseServerUrl/program'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Yeh server ko web view response dene se rokega
        },
        body: jsonEncode({
          'program_name': name,
          'department_id': deptId // JSON mein int hi jana chahiye
        }),
      );

      print("Server Response Status: ${response.statusCode}");
      print("Server Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Exception in addProgram: $e");
      return false;
    }
  }

  Future<bool> updateProgram(int id, String name, int deptId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseServerUrl/program/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'program_name': name, 'department_id': deptId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Exception in updateProgram: $e");
      return false;
    }
  }

  Future<bool> deleteProgram(int id, String token) async {
    try {
      final response = await http.delete(
          Uri.parse('$baseServerUrl/program/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          }
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Exception in deleteProgram: $e");
      return false;
    }
  }
}