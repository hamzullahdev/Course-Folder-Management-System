import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class QuestionController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;
  QuestionController({required this.token});

  var allocations = <dynamic>[].obs;
  var assessments = <dynamic>[].obs;
  var clos = <dynamic>[].obs;
  var questions = <dynamic>[].obs;
  var isLoading = false.obs;

  var selectedCloIds = <int>[].obs;

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

  Future<void> fetchClos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/clos'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        List<dynamic> fetchedClos = json.decode(response.body)['data'];

        // ✨ FIX: Natural Sorting Logic (String ki bajaye Numbers ko sort karega)
        fetchedClos.sort((a, b) {
          String codeA = a['clos_code']?.toString() ?? '';
          String codeB = b['clos_code']?.toString() ?? '';

          // String mein se sirf number nikalna (e.g., "CLO-10" se 10 nikalna)
          int numA = int.tryParse(codeA.replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
          int numB = int.tryParse(codeB.replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;

          // Agar dono mein numbers hain toh number ki base par sort karein
          if (numA != -1 && numB != -1) {
            return numA.compareTo(numB);
          }
          // Warna purana alphabetical order use karein
          return codeA.compareTo(codeB);
        });

        clos.assignAll(fetchedClos);

      } else {
        debugPrint("Failed to fetch CLOs from admin route. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error fetching CLOs: $e");
    }
  }

  Future<void> fetchQuestions([String? assessmentId]) async {
    isLoading.value = true;
    String targetId = assessmentId ?? 'all';
    final response = await http.get(Uri.parse('$baseUrl/teacher/assessments/$targetId/questions'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      questions.assignAll(json.decode(response.body)['data']);
    }
    isLoading.value = false;
  }

  Future<bool> addQuestion(String assessmentId, String text, int marks, List<int> cloIds) async {
    isLoading.value = true;

    final res = await http.post(
      Uri.parse('$baseUrl/teacher/questions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'assessment_id': assessmentId, 'question_text': text, 'total_marks': marks}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      var data = json.decode(res.body)['data'];
      int newQuestionId = data['id'];

      // CLO mapping pivot insert
      if (cloIds.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/teacher/question-clo/map'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: json.encode({'question_id': newQuestionId, 'clo_ids': cloIds}),
        );
      }

      await fetchQuestions(assessmentId);
      selectedCloIds.clear();
      Get.snackbar("Success", "Question and CLO mapped successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      isLoading.value = false;
      return true;
    } else {
      Get.snackbar("Error", json.decode(res.body)['message'] ?? "Failed to save question.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateQuestion(int questionId, String text, int marks, List<int> cloIds, String assessmentId) async {
    isLoading.value = true;

    final res = await http.put(
      Uri.parse('$baseUrl/teacher/questions/$questionId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'question_text': text, 'total_marks': marks}),
    );

    if (res.statusCode == 200) {
      if (cloIds.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/teacher/question-clo/map'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: json.encode({'question_id': questionId, 'clo_ids': cloIds}),
        );
      } else {
        await http.delete(Uri.parse('$baseUrl/teacher/question-clo/$questionId/remove'), headers: {'Authorization': 'Bearer $token'});
      }

      await fetchQuestions(assessmentId);
      Get.snackbar("Success", "Question updated successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      isLoading.value = false;
      return true;
    }
    isLoading.value = false;
    return false;
  }

  Future<void> deleteQuestion(int id, String? assessmentId) async {
    isLoading.value = true;
    final res = await http.delete(Uri.parse('$baseUrl/teacher/questions/$id'), headers: {'Authorization': 'Bearer $token'});
    if(res.statusCode == 200) {
      await fetchQuestions(assessmentId);
      Get.snackbar("Deleted", "Question deleted successfully.", backgroundColor: Colors.green, colorText: Colors.white);
    }
    isLoading.value = false;
  }

  void toggleClo(int cloId) {
    if (selectedCloIds.contains(cloId)) {
      selectedCloIds.remove(cloId);
    } else {
      selectedCloIds.add(cloId);
    }
  }
}