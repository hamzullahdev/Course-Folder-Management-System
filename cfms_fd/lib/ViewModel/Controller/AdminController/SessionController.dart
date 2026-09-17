import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionController {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // 1. Fetch All Sessions
  Future<Map<String, dynamic>> fetchSessions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          return {'success': true, 'data': decodedData};
        } else if (decodedData is Map<String, dynamic>) {
          return {
            'success': decodedData['success'] ?? true,
            'data': decodedData['data'] ?? [],
          };
        }
        return {'success': true, 'data': decodedData};
      } else {
        return {'success': false, 'message': 'Failed to load sessions from server.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Database Error: $e'};
    }
  }

  // 2. Create New Session (Sends direct DD/MM/YYYY)
  Future<Map<String, dynamic>> createSession(String token, String sName, String startDate, String endDate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          's_name': sName,
          'start_date': startDate, // Already in dd/mm/yyyy
          'end_date': endDate,     // Already in dd/mm/yyyy
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Session created successfully.', 'data': data['data']};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': data['message'] ?? 'Validation errors occurred.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create session.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }

  // 3. Update Existing Session
  Future<Map<String, dynamic>> updateSession(String token, int id, String sName, String startDate, String endDate) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/sessions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          's_name': sName,
          'start_date': startDate,
          'end_date': endDate,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Session updated successfully.'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': data['message'] ?? 'Validation errors occurred.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update session.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }

  // 4. Delete Session
  Future<Map<String, dynamic>> deleteSession(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/sessions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Session deleted successfully.'};
      } else {
        return {'success': false, 'message': 'Failed to delete session.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }
}