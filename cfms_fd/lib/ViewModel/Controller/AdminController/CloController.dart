import 'dart:convert';
import 'package:http/http.dart' as http;

class CloController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  List<dynamic> _extractList(dynamic body) {
    if (body == null) return [];
    var decoded = jsonDecode(body);

    if (decoded is List) return decoded;

    if (decoded is Map) {
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['data'] is Map && decoded['data']['data'] is List) {
        return decoded['data']['data'];
      }
    }

    return [];
  }

  Future<List<dynamic>> fetchDepartments(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/department"), headers: {"Authorization": "Bearer $token", "Accept": "application/json"});
      return res.statusCode == 200 ? _extractList(res.body) : [];
    } catch (e) {
      print("Fetch Departments Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchPrograms(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/program"), headers: {"Authorization": "Bearer $token", "Accept": "application/json"});
      return res.statusCode == 200 ? _extractList(res.body) : [];
    } catch (e) {
      print("Fetch Programs Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchCourses(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/course"), headers: {"Authorization": "Bearer $token", "Accept": "application/json"});
      return res.statusCode == 200 ? _extractList(res.body) : [];
    } catch (e) {
      print("Fetch Courses Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchSessions(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/sessions"), headers: {"Authorization": "Bearer $token", "Accept": "application/json"});
      return res.statusCode == 200 ? _extractList(res.body) : [];
    } catch (e) {
      print("Fetch Sessions Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchClos(String token) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/clos"), headers: {"Authorization": "Bearer $token", "Accept": "application/json"});
      return res.statusCode == 200 ? _extractList(res.body) : [];
    } catch (e) {
      print("Fetch CLOs Error: $e");
      return [];
    }
  }

  // Changed return type to Map to capture exact duplicate messages
  Future<Map<String, dynamic>> addClo(String cloCode, String description, dynamic courseId, dynamic sessionId, String token) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/clos"),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          "clos_code": cloCode,
          "clos_description": description,
          "course_id": int.tryParse(courseId.toString()) ?? courseId,
          "session_id": int.tryParse(sessionId.toString()) ?? sessionId,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'CLO created successfully.'};
      } else {
        var decoded = jsonDecode(res.body);
        String msg = decoded['message'] ?? 'This CLO code already exists in the table.';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      print("Add CLO Error: $e");
      return {'success': false, 'message': 'Network connection error.'};
    }
  }

  // Changed return type to Map to capture exact duplicate messages
  Future<Map<String, dynamic>> updateClo(dynamic id, String cloCode, String description, dynamic courseId, String token) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/clos/$id"),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          "clos_code": cloCode,
          "clos_description": description,
          "course_id": int.tryParse(courseId.toString()) ?? courseId
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        return {'success': true, 'message': 'CLO updated successfully.'};
      } else {
        var decoded = jsonDecode(res.body);
        String msg = decoded['message'] ?? 'This CLO code already exists in the table.';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      print("Update CLO Error: $e");
      return {'success': false, 'message': 'Network connection error.'};
    }
  }

  Future<bool> deleteClo(dynamic id, String token) async {
    try {
      final res = await http.delete(
          Uri.parse("$baseUrl/clos/$id"),
          headers: {"Authorization": "Bearer $token", "Accept": "application/json"}
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("Delete CLO Error: $e");
      return false;
    }
  }
}