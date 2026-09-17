import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ClosPlosMappingController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;
  ClosPlosMappingController({required this.token});

  var allocations = <dynamic>[].obs;
  var closList = <dynamic>[].obs;
  var plosList = <dynamic>[].obs;

  // Tracks mapped relationships (Key: PLO ID -> Value: CLO ID)
  // This helps enforce the rule: 1 PLO can only have 1 CLO
  var mappedPloToClo = <int, int>{}.obs;

  var isLoading = false.obs;

  Future<void> fetchAllocations() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/my-courses'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) allocations.assignAll(json.decode(response.body)['data']);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMappingData(String courseId) async {
    isLoading.value = true;
    mappedPloToClo.clear();

    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/course/$courseId/clo-plo-mapping'), headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        var data = json.decode(response.body)['data'];

        // Populate Lists
        closList.assignAll(data['clos']);
        plosList.assignAll(data['plos']);

        // Populate existing mappings into our tracking map
        List<dynamic> existingMappings = data['mappings'];
        for (var map in existingMappings) {
          int cloId = int.parse(map['clo_id'].toString());
          int ploId = int.parse(map['plo_id'].toString());
          mappedPloToClo[ploId] = cloId;
        }
      }
    } catch (e) {
      debugPrint("Error fetching mappings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Checkbox Toggle Logic
  void toggleMapping(int cloId, int ploId, bool isChecked) {
    if (isChecked) {
      // RULE: Check if PLO is already mapped to another CLO
      if (mappedPloToClo.containsKey(ploId) && mappedPloToClo[ploId] != cloId) {
        String existingCloCode = closList.firstWhere((c) => c['id'] == mappedPloToClo[ploId], orElse: () => {'clos_code': 'another CLO'})['clos_code'];
        Get.snackbar(
            "Mapping Rule Violation",
            "This PLO is already mapped to $existingCloCode. One PLO can only be mapped to one CLO.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4)
        );
        return; // Reject the check
      }
      mappedPloToClo[ploId] = cloId; // Assign
    } else {
      mappedPloToClo.remove(ploId); // Un-assign
    }
  }

  // Check if a specific checkbox should be ticked
  bool isMapped(int cloId, int ploId) {
    return mappedPloToClo[ploId] == cloId;
  }

  Future<bool> saveMappings(String courseId) async {
    isLoading.value = true;

    // Convert map to array of objects for API
    List<Map<String, int>> payloadMappings = [];
    mappedPloToClo.forEach((ploId, cloId) {
      payloadMappings.add({'clo_id': cloId, 'plo_id': ploId});
    });

    try {
      final response = await http.post(
          Uri.parse('$baseUrl/teacher/clo-plo-mapping'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: json.encode({
            'course_id': courseId,
            'mappings': payloadMappings
          })
      );

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Mappings saved successfully!", backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar("Error", "Failed to save mappings.", backgroundColor: Colors.redAccent, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Network error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}