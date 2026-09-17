import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ResultController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;
  ResultController({required this.token});

  var allocations = <dynamic>[].obs;
  var assessments = <dynamic>[].obs;
  var questions = <dynamic>[].obs;
  var enrolledStudents = <dynamic>[].obs;
  var results = <dynamic>[].obs;

  var isLoading = false.obs;

  Future<void> fetchAllocations() async {
    final response = await http.get(Uri.parse('$baseUrl/teacher/my-courses'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      allocations.assignAll(json.decode(response.body)['data']);
    }
  }

  Future<void> fetchAssessments(String allocationId) async {
    final response = await http.get(Uri.parse('$baseUrl/teacher/assessments/$allocationId'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      assessments.assignAll(json.decode(response.body)['data']);
    }
  }

  Future<void> fetchQuestions(String assessmentId) async {
    final response = await http.get(Uri.parse('$baseUrl/teacher/assessments/$assessmentId/questions'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      questions.assignAll(json.decode(response.body)['data']);
    }
  }

  Future<void> fetchEnrolledStudents(String allocationId) async {
    isLoading.value = true;
    final response = await http.get(Uri.parse('$baseUrl/teacher/allocations/$allocationId/students'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      enrolledStudents.assignAll(json.decode(response.body)['data']);
    }
    isLoading.value = false;
  }

  Future<void> fetchResults(String questionId) async {
    isLoading.value = true;
    final response = await http.get(Uri.parse('$baseUrl/teacher/questions/$questionId/results'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      results.assignAll(json.decode(response.body)['data']);
    }
    isLoading.value = false;
  }

  Future<bool> saveBulkResults(String questionId, Map<String, String> marksData) async {
    isLoading.value = true;
    final res = await http.post(
      Uri.parse('$baseUrl/teacher/results/bulk'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'question_id': questionId,
        'marks': marksData
      }),
    );

    if (res.statusCode == 200) {
      Get.snackbar("Success", "Marks saved successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      await fetchResults(questionId);
      isLoading.value = false;
      return true;
    } else {
      Get.snackbar("Error", json.decode(res.body)['message'] ?? "Failed to save marks.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      isLoading.value = false;
      return false;
    }
  }

  Future<void> updateSingleResult(int resultId, int newMarks, String questionId) async {
    isLoading.value = true;
    final res = await http.put(
      Uri.parse('$baseUrl/teacher/results/$resultId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'obtained_marks': newMarks}),
    );

    if (res.statusCode == 200) {
      await fetchResults(questionId);
      Get.snackbar("Success", "Result updated successfully.", backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("Error", "Failed to update result.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
    isLoading.value = false;
  }

  Future<void> deleteResult(int id, String questionId) async {
    isLoading.value = true;
    final res = await http.delete(Uri.parse('$baseUrl/teacher/results/$id'), headers: {'Authorization': 'Bearer $token'});
    if(res.statusCode == 200) {
      await fetchResults(questionId);
      Get.snackbar("Deleted", "Result deleted successfully.", backgroundColor: Colors.green, colorText: Colors.white);
    }
    isLoading.value = false;
  }
}