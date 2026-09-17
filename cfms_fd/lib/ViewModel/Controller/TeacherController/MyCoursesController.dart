import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MyCoursesController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;

  MyCoursesController({required this.token});

  var allocations = <dynamic>[].obs;
  var filteredAllocations = <dynamic>[].obs;
  var sessions = <dynamic>[].obs;

  var selectedSessionId = ''.obs;
  var isLoading = false.obs;

  var uploadedFilesMap = <String, int>{}.obs;
  var statusMap = <String, String>{}.obs;

  // ✨ NEW: Rejection ke baad resubmit ko lock/unlock karne ke liye
  var unlockedForResubmit = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyCourses();
  }

  Future<void> fetchMyCourses() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/my-courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          allocations.assignAll(jsonData['data'] ?? []);
          sessions.assignAll(jsonData['sessions'] ?? []);

          for (var alloc in allocations) {
            String allocId = alloc['id']?.toString() ?? '';
            statusMap[allocId] = (alloc['status'] ?? 'in progress').toString().toLowerCase();
            int count = alloc['file_submissions_count'] ?? alloc['submissions_count'] ?? 0;
            uploadedFilesMap[allocId] = count;
          }
          uploadedFilesMap.refresh();
          statusMap.refresh();

          if (selectedSessionId.value.isEmpty && sessions.isNotEmpty) {
            selectedSessionId.value = sessions.first['id'].toString();
          }

          applyFilter();
        }
      } else {
        Get.snackbar("Error", "Failed to load courses.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Network connection failed.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilter() {
    if (selectedSessionId.value.isEmpty) {
      filteredAllocations.assignAll(allocations);
    } else {
      var filtered = allocations.where((a) => a['session_id'].toString() == selectedSessionId.value).toList();
      filteredAllocations.assignAll(filtered);
    }
  }

  bool isFolderSubmitted(dynamic allocationId) {
    String status = statusMap[allocationId.toString()] ?? 'in progress';
    return status == 'submitted';
  }

  bool isFolderAccepted(dynamic allocationId) {
    String status = statusMap[allocationId.toString()] ?? 'in progress';
    return status == 'approved' || status == 'accepted';
  }

  bool isFolderRejected(dynamic allocationId) {
    return statusMap[allocationId.toString()] == 'rejected';
  }

  String getRejectionReason(dynamic allocationId) {
    var alloc = allocations.firstWhere((a) => a['id'].toString() == allocationId.toString(), orElse: () => {});
    return alloc['reason'] ?? 'Please check feedback and resubmit.';
  }

  // ✨ NEW: Helper methods to manage Resubmit Lock
  bool canResubmit(dynamic allocationId) {
    return unlockedForResubmit[allocationId.toString()] ?? false;
  }

  void unlockResubmit(dynamic allocationId) {
    unlockedForResubmit[allocationId.toString()] = true;
    unlockedForResubmit.refresh();
  }

  Future<void> submitFolder(dynamic allocationId) async {
    isLoading.value = true;
    try {
      final res = await http.post(
          Uri.parse('$baseUrl/teacher/my-courses/$allocationId/submit'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          }
      );

      if (res.statusCode == 200) {
        statusMap[allocationId.toString()] = 'submitted';
        statusMap.refresh();
        Get.snackbar("Success", "Folder submitted successfully!", backgroundColor: Colors.green, colorText: Colors.white);
        await fetchMyCourses();
      } else {
        String errorMsg = "Error Code: ${res.statusCode}";
        try {
          var decoded = json.decode(res.body);
          errorMsg = decoded['error'] ?? decoded['message'] ?? errorMsg;
        } catch (e) {
          errorMsg = "Backend route not found or server crashed.";
        }
        Get.snackbar("Submission Failed", errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
      }
    } catch (e) {
      Get.snackbar("Exception", "Network connection failed.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ✨ FIX: Token ko URL ke andar attach kar diya hai taake browser authorize ho sake
  Future<void> downloadZip(int id) async {
    try {
      String url = "$baseUrl/teacher/allocations/$id/download-zip?token=$token";
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

  String calculateSemester(String batchName, String sessionName) {
    try {
      RegExp yearRegExp = RegExp(r'\d{4}');
      var batchMatch = yearRegExp.firstMatch(batchName);
      var sessionMatch = yearRegExp.firstMatch(sessionName);

      if (batchMatch != null) {
        int admissionYear = int.parse(batchMatch.group(0)!);
        int sessionYear = sessionMatch != null ? int.parse(sessionMatch.group(0)!) : DateTime.now().year;

        int yearDiff = sessionYear - admissionYear;
        int semester = 1;

        String sLower = sessionName.toLowerCase();
        String bLower = batchName.toLowerCase();

        if (sLower.contains('fall')) {
          semester = (yearDiff * 2) + 1;
        } else if (sLower.contains('spring')) {
          semester = (yearDiff * 2);
        } else if (sLower.contains('summer')) {
          semester = (yearDiff * 2);
        } else {
          semester = (yearDiff * 2) + 1;
        }

        if (bLower.contains('spring')) semester += 1;
        if (semester < 1) semester = 1;

        String suffix = "th";
        if (semester % 10 == 1 && semester % 100 != 11) suffix = "st";
        else if (semester % 10 == 2 && semester % 100 != 12) suffix = "nd";
        else if (semester % 10 == 3 && semester % 100 != 13) suffix = "rd";

        if (sLower.contains('summer')) return "$semester$suffix (Summer)";
        return "$semester$suffix";
      }
    } catch (e) {
      debugPrint("Semester Calculation Error: $e");
    }
    return "1st";
  }

  int getTotalRequiredFiles(String courseName) {
    String cLower = courseName.toLowerCase();
    return (cLower.contains('islamiyat') || cLower.contains('pakistan studies')) ? 97 : 100;
  }

  int getUploadedFilesCount(dynamic allocationId) => uploadedFilesMap[allocationId.toString()] ?? 0;
}