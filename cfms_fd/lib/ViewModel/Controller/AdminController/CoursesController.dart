import 'dart:convert';
import 'package:http/http.dart' as http;

class CoursesController {
  // NOTE: If using a real device, make sure to run 'adb reverse tcp:8000 tcp:8000'
  // in your terminal, or replace 127.0.0.1 with your local PC IP address.
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  List<dynamic> _safeParseList(dynamic responseBody) {
    try {
      var decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
    } catch (e) {
      print("JSON parsing exception: $e");
    }
    return [];
  }

  // Fetch all courses from database
  Future<List<dynamic>> fetchCourses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/course'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return _safeParseList(response.body);
      }
    } catch (e) {
      print("Error fetching courses: $e");
    }
    return [];
  }

  // Fetch all departments
  Future<List<dynamic>> fetchDepartments(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/department'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return _safeParseList(response.body);
      }
    } catch (e) {
      print("Error fetching departments: $e");
    }
    return [];
  }

  // Fetch all programs
  Future<List<dynamic>> fetchPrograms(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/program'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return _safeParseList(response.body);
      }
    } catch (e) {
      print("Error fetching programs: $e");
    }
    return [];
  }

  // Add a new course manually
  Future<Map<String, dynamic>> addCourse(String name, String code, String shortName, String creditHrs, int programId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/course'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course_name': name,
          'course_code': code,
          'short_name': shortName,
          'credit_hrs': creditHrs,
          'program_id': programId,
        }),
      );

      var decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Course added successfully.', 'data': decoded['data']};
      } else if (response.statusCode == 422) {
        return {'success': false, 'errors': decoded['errors']};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to add course.'};
    } catch (e) {
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  // Update an existing course entry
  Future<Map<String, dynamic>> updateCourse(int id, String name, String code, String shortName, String creditHrs, int programId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/course/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course_name': name,
          'course_code': code,
          'short_name': shortName,
          'credit_hrs': creditHrs,
          'program_id': programId,
        }),
      );

      var decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Course updated successfully.', 'data': decoded['data']};
      } else if (response.statusCode == 422) {
        return {'success': false, 'errors': decoded['errors']};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to update course.'};
    } catch (e) {
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  // Delete a course record
  Future<Map<String, dynamic>> deleteCourse(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/course/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      var decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Course deleted successfully.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to delete course.'};
    } catch (e) {
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  // Bulk data upload via Excel sheets
  Future<Map<String, dynamic>> uploadExcel(String filePath, String token) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/course/import'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Excel spreadsheet datasets imported successfully.'
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Validation failure within spreadsheet records.',
          'errors': decoded['errors']
        };
      }
      return {
        'success': false,
        'message': decoded['message'] ?? 'Internal application server error occurred.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Excel transmission pipeline exception: $e'
      };
    }
  }
}