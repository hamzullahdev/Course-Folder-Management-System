import 'dart:convert';
import 'package:http/http.dart' as http;

class BatchController {
  // Base API URL
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // 1. Fetch All Batches
  Future<Map<String, dynamic>> fetchBatches(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/batches'),
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
            'data': decodedData['data'] ?? decodedData['batches'] ?? [],
          };
        }
        return {'success': true, 'data': decodedData};
      } else {
        return {'success': false, 'message': 'Failed to load batches from database.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Database Error: $e'};
    }
  }

  // 2. Fetch All Programs Dynamically
  Future<Map<String, dynamic>> fetchPrograms(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/program'),
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
            'data': decodedData['data'] ?? decodedData['programs'] ?? [],
          };
        }
        return {'success': true, 'data': decodedData};
      } else {
        return {'success': false, 'message': 'Failed to load programs from database.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Database Error: $e'};
    }
  }

  // 3. Fetch All Departments Dynamically
  Future<Map<String, dynamic>> fetchDepartments(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/department'),
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
            'data': decodedData['data'] ?? decodedData['departments'] ?? decodedData['department'] ?? [],
          };
        }
        return {'success': true, 'data': decodedData};
      } else {
        return {'success': false, 'message': 'Failed to load departments from database.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Database Error: $e'};
    }
  }

  // 4. Create New Batch
  Future<Map<String, dynamic>> createBatch(String token, String batchName, String programId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/batches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'batch_name': batchName,
          'program_id': programId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Batch created successfully.',
          'data': data['data']
        };
      } else if (response.statusCode == 422) {
        String errorMsg = data['message'] ?? 'Validation failed.';
        if (data['errors'] != null && data['errors']['program_id'] != null) {
          errorMsg = data['errors']['program_id'][0];
        }
        return {'success': false, 'message': errorMsg};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create batch.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }

  // 5. Update Existing Batch
  Future<Map<String, dynamic>> updateBatch(String token, int id, String batchName, String programId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/batches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'batch_name': batchName,
          'program_id': programId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Batch updated successfully.',
          'data': data['data']
        };
      } else if (response.statusCode == 422) {
        String errorMsg = data['message'] ?? 'Validation failed.';
        if (data['errors'] != null && data['errors']['program_id'] != null) {
          errorMsg = data['errors']['program_id'][0];
        }
        return {'success': false, 'message': errorMsg};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update batch.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }

  // 6. Delete Batch
  Future<Map<String, dynamic>> deleteBatch(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/batches/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          return {'success': data['success'] ?? true, 'message': data['message'] ?? 'Deleted successfully.'};
        }
        return {'success': true, 'message': 'Batch deleted successfully.'};
      } else {
        return {'success': false, 'message': 'Failed to delete batch from server.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'API Error: $e'};
    }
  }
}