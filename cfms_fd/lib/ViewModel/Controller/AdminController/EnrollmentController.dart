import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class EnrollmentController extends GetxController {
  // ⚠️ NOTE: Update to your local IP if running on physical device
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  // ✨ FIX 1: Add Token & Headers (Pehle yeh missing tha)
  String authToken = "";

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  var allEnrollments = <dynamic>[].obs;
  var filteredEnrollments = <dynamic>[].obs;
  var isLoading = false.obs;
  var filePathDisplay = ''.obs;
  File? selectedFile;

  // Filter Dropdown Lists
  var departments = <String>[].obs;
  var programs = <String>[].obs;
  var sessions = <String>[].obs;
  var sections = <String>[].obs;
  var subjects = <String>[].obs;

  // Selected Filter Values
  var selectedDept = ''.obs;
  var selectedProg = ''.obs;
  var selectedSess = ''.obs;
  var selectedSec = ''.obs;
  var selectedSub = ''.obs;

  // ✨ FIX 2: Initialize Data (Called from UI to set token before fetching)
  void initializeData(String token) {
    authToken = token;
    fetchDropdownData();
    fetchEnrollments();
  }

  @override
  void onInit() {
    super.onInit();
    // Direct fetch hataya taake pehle token set ho
  }

  // Safe JSON extraction helper for Laravel API formats
  List _extractDataArray(String responseBody) {
    try {
      var decoded = json.decode(responseBody);
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'] ?? [];
      } else if (decoded is List) {
        return decoded;
      }
    } catch (e) {
      debugPrint("JSON extraction error: $e");
    }
    return [];
  }

  // Fetch unique master data for filters from backend
  Future<void> fetchDropdownData() async {
    try {
      // ✨ FIX 3: Added headers: _getHeaders() to ALL API calls
      var deptRes = await http.get(Uri.parse('$baseUrl/department'), headers: _getHeaders());
      if (deptRes.statusCode == 200) {
        var data = _extractDataArray(deptRes.body);
        departments.assignAll(data.map((e) => e['dept_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList());
      }

      var progRes = await http.get(Uri.parse('$baseUrl/program'), headers: _getHeaders());
      if (progRes.statusCode == 200) {
        var data = _extractDataArray(progRes.body);
        programs.assignAll(data.map((e) => e['program_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList());
      }

      var sessRes = await http.get(Uri.parse('$baseUrl/sessions'), headers: _getHeaders());
      if (sessRes.statusCode == 200) {
        var data = _extractDataArray(sessRes.body);
        sessions.assignAll(data.map((e) => e['s_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList());
      }

      var courseRes = await http.get(Uri.parse('$baseUrl/course'), headers: _getHeaders());
      if (courseRes.statusCode == 200) {
        var data = _extractDataArray(courseRes.body);
        subjects.assignAll(data.map((e) => e['course_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList());
      }
    } catch (e) {
      debugPrint("❌ Exception fetching dropdown master data: $e");
    }
  }

  // Fetch all enrollments for grid mapping
  Future<void> fetchEnrollments() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/enrollments'), headers: _getHeaders());

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          allEnrollments.assignAll(jsonData['data']);
          populateSectionFilter();
          applyFilters();
        } else {
          debugPrint("⚠️ Backend success flag is false or data array is null.");
        }
      } else {
        Get.snackbar("Error", "Failed to load records from database. Status: ${response.statusCode}",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("❌ Exception caught inside fetchEnrollments: $e");
      Get.snackbar("Exception", "Network or parsing error occurred.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void populateSectionFilter() {
    try {
      var secSet = allEnrollments
          .map((e) => e['section']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      sections.assignAll(secSet.toList());
    } catch (e) {
      debugPrint("❌ Error extracting sections mapping: $e");
    }
  }

  void applyFilters() {
    var intermediateList = allEnrollments.where((item) {
      String d = item['student']?['program']?['department']?['dept_name']?.toString() ?? '';
      String p = item['student']?['program']?['program_name']?.toString() ?? '';
      String ss = item['course_offered']?['session']?['s_name']?.toString() ?? '';
      String sc = item['section']?.toString() ?? '';
      String sb = item['course_offered']?['course']?['course_name']?.toString() ?? '';

      bool matchesDept = selectedDept.value.isEmpty || d == selectedDept.value;
      bool matchesProg = selectedProg.value.isEmpty || p == selectedProg.value;
      bool matchesSess = selectedSess.value.isEmpty || ss == selectedSess.value;
      bool matchesSec  = selectedSec.value.isEmpty || sc == selectedSec.value;
      bool matchesSub  = selectedSub.value.isEmpty || sb == selectedSub.value;

      return matchesDept && matchesProg && matchesSess && matchesSec && matchesSub;
    }).toList();

    filteredEnrollments.assignAll(intermediateList);
  }

  Future<void> browseExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: false, // Ensures app won't crash on large files
    );

    if (result != null && result.files.single.path != null) {
      selectedFile = File(result.files.single.path!);
      filePathDisplay.value = result.files.single.name;
    } else {
      Get.snackbar("Cancelled", "File browsing operation was cancelled.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orangeAccent, colorText: Colors.white);
    }
  }

  Future<void> importSpreadsheet() async {
    if (selectedFile == null) {
      Get.snackbar("Warning", "Please browse and select a valid document file first.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.amber, colorText: Colors.black);
      return;
    }

    isLoading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/enrollments/import'));
      request.headers.addAll(_getHeaders()); // ✨ ADD HEADERS HERE
      request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar("Success", responseData['message'] ?? "Data processed completely.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        filePathDisplay.value = '';
        selectedFile = null;

        await fetchDropdownData();
        await fetchEnrollments();
      } else {
        String realErrorMessage = responseData['error'] ?? responseData['message'] ?? "Unknown backend error occurred.";
        debugPrint("❌ Backend Error: ${response.body}");

        Get.snackbar("Import Failure", realErrorMessage,
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
      }
    } catch (e) {
      Get.snackbar("Runtime Error", "Upload execution failed: $e",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEnrollment(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/enrollments/$id'), headers: _getHeaders()); // ✨ ADD HEADERS
      if (response.statusCode == 200) {
        Get.snackbar("Deleted", "Enrollment record entry removed cleanly.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchEnrollments();
      }
    } catch (e) {
      Get.snackbar("Exception", "Failed to reach server.");
    }
  }

  Future<void> updateEnrollment(int id, Map<String, dynamic> updatePayload) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/enrollments/$id'),
        // ✨ MERGE HEADERS WITH CONTENT-TYPE
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode(updatePayload),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Updated", "Enrollment updated accurately.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchEnrollments();
      } else {
        Get.snackbar("Update Failed", "Input parameters mismatch database constraints.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Action failed due to network error.");
    } finally {
      isLoading.value = false;
    }
  }
}