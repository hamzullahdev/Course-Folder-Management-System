import 'dart:convert';
import 'package:http/http.dart' as http;

class PLOsController {
  final String baseServerUrl = "http://127.0.0.1:8000/api";

  // 1. Fetch All PLOs
  Future<List<dynamic>> fetchPLOs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseServerUrl/admin/plo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        return body['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Exception in fetchPLOs: $e");
      return [];
    }
  }

  // 2. Fetch Departments
  Future<List<dynamic>> fetchDepartments(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseServerUrl/admin/department'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        return body is List ? body : (body['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Exception in fetchDepartments: $e");
      return [];
    }
  }

  // 3. Fetch Programs
  Future<List<dynamic>> fetchPrograms(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseServerUrl/admin/program'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        return body is List ? body : (body['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Exception in fetchPrograms: $e");
      return [];
    }
  }

  // 4. Add New PLO (With local checking validation)
  Future<bool> addPLO(String ploCode, String description, int programId, String token) async {
    try {
      // Fetching current list to make sure no duplicate plo_code exists within the target program
      List<dynamic> existingPLOs = await fetchPLOs(token);
      bool isDuplicate = existingPLOs.any((plo) =>
      plo['program_id'] == programId &&
          plo['plo_code'].toString().trim().toLowerCase() == ploCode.trim().toLowerCase()
      );

      if (isDuplicate) {
        print("Validation Error: This PLO code already exists for the selected program.");
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseServerUrl/admin/plo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'plo_code': ploCode,
          'plo_description': description,
          'program_id': programId,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Exception in addPLO: $e");
      return false;
    }
  }

  // 5. Update PLO
  Future<bool> updatePLO(int id, String ploCode, String description, int programId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseServerUrl/admin/plo/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'plo_code': ploCode,
          'plo_description': description,
          'program_id': programId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Exception in updatePLO: $e");
      return false;
    }
  }

  // 6. Delete PLO
  Future<bool> deletePLO(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseServerUrl/admin/plo/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Exception in deletePLO: $e");
      return false;
    }
  }
}