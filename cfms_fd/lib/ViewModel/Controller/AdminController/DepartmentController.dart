import 'dart:convert';
import 'package:http/http.dart' as http;

class DepartmentController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin/department";

  Future<List> fetchDepartments(String token) async {
    final response = await http.get(Uri.parse(baseUrl), headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] : [];
  }

  Future<bool> addDepartment(String name, String token) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'dept_name': name}),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateDepartment(int id, String name, String token) async {
    // Note: PUT request ke liye id URL mein honi chahiye
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'dept_name': name}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteDepartment(int id, String token) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200;
  }
}