import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ReportController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";
  final String token;

  ReportController({required this.token});

  var isLoading = false.obs;
  var isDataLoading = false.obs;

  var reportsList = <dynamic>[].obs;

  // Master Data
  var rawDepartments = <dynamic>[].obs;
  var rawPrograms = <dynamic>[].obs;

  // ✨ FIX: In sabko completely independent rakha gaya hai
  var sessions = <dynamic>[].obs;
  var batches = <dynamic>[].obs;
  var teachers = <dynamic>[].obs;
  var sections = <String>[].obs;

  var completionContext = 'complete'.obs;

  var selectedDept = ''.obs;
  var selectedProg = ''.obs;
  var selectedSess = ''.obs;
  var selectedBatch = ''.obs;
  var selectedSec = ''.obs;
  var selectedTeacher = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFilters();
    fetchReports();
  }

  Future<void> fetchFilters() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/filters'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body)['data'];
        rawDepartments.assignAll(data['departments'] ?? []);
        rawPrograms.assignAll(data['programs'] ?? []);
        sessions.assignAll(data['sessions'] ?? []);
        batches.assignAll(data['batches'] ?? []);
        teachers.assignAll(data['teachers'] ?? []);
        sections.assignAll(List<String>.from(data['sections'] ?? []));
      }
    } catch (e) {
      debugPrint("Filter API Error: $e");
    }
  }

  Future<void> fetchReports() async {
    isDataLoading.value = true;
    String query = "?completion_context=${completionContext.value}";
    if (selectedDept.value.isNotEmpty) query += "&department_id=${selectedDept.value}";
    if (selectedProg.value.isNotEmpty) query += "&program_id=${selectedProg.value}";
    if (selectedSess.value.isNotEmpty) query += "&session_id=${selectedSess.value}";
    if (selectedBatch.value.isNotEmpty) query += "&batch_id=${selectedBatch.value}";
    if (selectedSec.value.isNotEmpty) query += "&section=${selectedSec.value}";
    if (selectedTeacher.value.isNotEmpty) query += "&teacher_id=${selectedTeacher.value}";

    try {
      final res = await http.get(Uri.parse('$baseUrl/reports$query'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        reportsList.assignAll(jsonDecode(res.body)['data']);
      } else {
        reportsList.clear();
      }
    } catch (e) {
      debugPrint("Reports API Error: $e");
    } finally {
      isDataLoading.value = false;
    }
  }

  Future<void> acceptPackage(int id) async {
    isLoading.value = true;
    try {
      final res = await http.post(Uri.parse('$baseUrl/reports/$id/accept'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        Get.snackbar("Success", "Course package marked as Approved.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchReports();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPackage(int id, String reason) async {
    if (reason.trim().isEmpty) return;
    isLoading.value = true;
    try {
      final res = await http.post(
          Uri.parse('$baseUrl/reports/$id/reject'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'reason': reason})
      );
      if (res.statusCode == 200) {
        Get.snackbar("Rejected", "Exception logged successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchReports();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadZip(int id) async {
    try {
      String url = "$baseUrl/reports/$id/download-zip?token=$token";
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("Error", "Could not trigger file download mechanism.", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Download ZIP error: $e");
    }
  }

  // ✨ FIX: Program gets filtered by Department, but others remain untouched
  List<dynamic> get filteredPrograms {
    if (selectedDept.value.isEmpty) return rawPrograms;
    return rawPrograms.where((p) => p['department_id'].toString() == selectedDept.value).toList();
  }

  // Helper to completely reset dropdowns
  void resetAllFilters() {
    selectedDept.value = '';
    selectedProg.value = '';
    selectedSess.value = '';
    selectedBatch.value = '';
    selectedSec.value = '';
    selectedTeacher.value = '';
  }
}