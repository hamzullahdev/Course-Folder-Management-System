import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ReportChecklistController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;

  ReportChecklistController({required this.token});

  var checklist = <dynamic>[].obs;
  var isLoading = false.obs;

  Future<void> fetchChecklist(String allocationId) async {
    isLoading.value = true;
    try {
      // Backend ke maujooda checklist API ko call kar raha hai
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

  Future<void> viewFile(String filePath) async {
    if (filePath.isEmpty) {
      Get.snackbar("Error", "File path is missing.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    try {
      String normalizedPath = filePath.replaceAll('\\', '/');
      String rootUrl = baseUrl.replaceAll('/api', '');
      String fileUrl = "$rootUrl/storage/$normalizedPath";

      final Uri url = Uri.parse(Uri.encodeFull(fileUrl));

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("Error", "Could not open the file.", backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("File launch exception: $e");
      Get.snackbar("Error", "An error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}