import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ChecklistController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;

  ChecklistController({required this.token});

  var allocations = <dynamic>[].obs;
  var checklist = <dynamic>[].obs;
  var isLoading = false.obs;

  Future<void> fetchAllocations() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/my-courses'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        allocations.assignAll(json.decode(response.body)['data']);
      }
    } catch (e) {
      debugPrint("Error fetching allocations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchChecklist(String allocationId) async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/allocations/$allocationId/checklist'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        checklist.assignAll(json.decode(response.body)['data']);
      } else {
        checklist.clear();
      }
    } catch (e) {
      debugPrint("Error fetching checklist: $e");
      checklist.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ✨ FIX: Real File Viewing Logic using url_launcher
  Future<void> viewFile(String filePath) async {
    if (filePath.isEmpty) {
      Get.snackbar("Error", "File path is missing or invalid.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      // Clean the file path (replace backslashes with forward slashes for URLs)
      String normalizedPath = filePath.replaceAll('\\', '/');

      // Extract root URL (Remove '/api' from baseUrl)
      String rootUrl = baseUrl.replaceAll('/api', '');

      // Construct the full public URL for the stored file
      String fileUrl = "$rootUrl/storage/$normalizedPath";

      final Uri url = Uri.parse(fileUrl);

      // Launch the URL in the external browser / default app
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("Error", "Could not open the file. Please check if the file exists on the server.", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("File launch exception: $e");
      Get.snackbar("Error", "An unexpected error occurred while trying to open the file.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}