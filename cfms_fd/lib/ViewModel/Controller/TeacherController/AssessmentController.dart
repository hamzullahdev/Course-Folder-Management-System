import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AssessmentController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;
  AssessmentController({required this.token});

  var allocations = <dynamic>[].obs;
  var assessments = <dynamic>[].obs;
  var isLoading = false.obs;

  final List<String> assessmentTypes = [
    'Quiz-1', 'Quiz-2', 'Quiz-3', 'Quiz-4', 'Quiz-5', 'Quiz-6',
    'Assignment-1', 'Assignment-2', 'Assignment-3', 'Assignment-4', 'Assignment-5', 'Assignment-6',
    'Mid Exam', 'Final Exam'
  ];

  Future<void> fetchAllocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/my-courses'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        allocations.assignAll(json.decode(response.body)['data']);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch courses.");
    }
  }

  Future<void> fetchAssessments(String allocationId) async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/assessments/$allocationId'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        assessments.assignAll(json.decode(response.body)['data']);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch assessments.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAssessment(String allocId, String type, int weightage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/assessments'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'course_allocation_id': allocId, 'type': type, 'weightage': weightage}),
      );

      if (response.statusCode == 200) {
        fetchAssessments(allocId);
        Get.snackbar("Success", "Assessment saved successfully!");
      } else {
        // ✨ FIX: Safely parse error taake button freeze na ho
        var decoded = json.decode(response.body);
        Get.snackbar("Error", decoded['message'] ?? "Error saving assessment.");
      }
    } catch (e) {
      Get.snackbar("Error", "Server error. Could not save assessment.");
    }
  }

  Future<void> deleteAssessment(int id, String allocId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/teacher/assessments/$id'), headers: {'Authorization': 'Bearer $token'});
      fetchAssessments(allocId);
      Get.snackbar("Deleted", "Assessment removed.");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete assessment.");
    }
  }

  Future<void> updateAssessment(int id, String allocId, int weightage) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teacher/assessments/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'weightage': weightage}),
      );

      if (response.statusCode == 200) {
        fetchAssessments(allocId);
        Get.back(); // Dialog band karne ke liye
        Get.snackbar("Success", "Assessment updated!");
      } else {
        var decoded = json.decode(response.body);
        Get.snackbar("Error", decoded['message'] ?? "Update failed.");
      }
    } catch (e) {
      Get.snackbar("Error", "Server error. Could not update assessment.");
    }
  }
}