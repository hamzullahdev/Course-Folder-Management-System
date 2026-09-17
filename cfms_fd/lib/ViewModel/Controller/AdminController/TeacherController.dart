import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TeacherController extends GetxController {
  // ⚠️ Modify base URL context as per your physical testing configuration
  final String baseUrl = "http://127.0.0.1:8000/api/admin";
  String authToken = "";

  // Core Reactive States
  var isLoading = false.obs;
  var isUploading = false.obs;
  var selectedFilePath = ''.obs;
  File? excelFile;

  // Datasets Storage Matrices
  var allTeachers = <dynamic>[].obs;
  var filteredTeachers = <dynamic>[].obs;

  // Dropdown Filtering Items
  var masterDepartments = <dynamic>[].obs;
  var departments = <String>[].obs;
  var selectedDepartment = ''.obs;

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  void initializeData(String token) {
    authToken = token;
    fetchDropdownFilters();
    fetchTeachers();
  }

  List<dynamic> _safeParseList(dynamic resBody) {
    try {
      var decoded = jsonDecode(resBody);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
    } catch (e) {
      print("JSON extraction parsing fault: $e");
    }
    return [];
  }

  // ================= FETCH ALL DEPARTMENTS =================
  Future<void> fetchDropdownFilters() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/department'), headers: _getHeaders()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        masterDepartments.assignAll(_safeParseList(response.body));
        List<String> depts = masterDepartments
            .map((e) => (e['dept_name'] ?? e['name'] ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        departments.assignAll(depts.toSet().toList());
      }
    } catch (e) {
      print("Error cascading dropdown layers: $e");
    }
  }

  // ================= FETCH ALL TEACHERS =================
  Future<void> fetchTeachers() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/teachers'), headers: _getHeaders()).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        allTeachers.assignAll(_safeParseList(response.body));
        applyFilters();
      } else {
        showSnackBar("Fetch Failure", "Could not query records from server configuration layout.", isError: true);
      }
    } catch (e) {
      showSnackBar("Connection Fault", "Network infrastructure pipeline breakdown: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DYNAMIC FILTER APPLICATION =================
  void onDepartmentChanged(String? val) {
    selectedDepartment.value = (val ?? '').trim();
    applyFilters();
  }

  void applyFilters() {
    if (allTeachers.isEmpty) {
      filteredTeachers.clear();
      return;
    }

    var dynamicFilter = allTeachers.where((teacher) {
      bool matchesDept = selectedDepartment.value.isEmpty;
      if (selectedDepartment.value.isNotEmpty && teacher['department'] != null) {
        String deptName = (teacher['department']['dept_name'] ?? teacher['department']['name'] ?? '').toString().trim();
        matchesDept = (deptName.toLowerCase() == selectedDepartment.value.toLowerCase());
      }
      return matchesDept;
    }).toList();

    filteredTeachers.assignAll(dynamicFilter);
  }

  // ================= BROWSE FILE PIPELINE =================
  Future<void> browseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        selectedFilePath.value = result.files.single.path!;
        excelFile = File(result.files.single.path!);
      } else {
        showSnackBar("Operation Halting", "Spreadsheet import matrix setup discarded by operator.", isError: true);
      }
    } catch (e) {
      showSnackBar("File Exception", "Critical operating system layer browsing fault: $e", isError: true);
    }
  }

  // ================= UPLOAD BULK EXCEL =================
  Future<void> importExcel() async {
    if (excelFile == null) {
      showSnackBar("Selection Empty", "Please choose a valid spreadsheet configuration template first.", isError: true);
      return;
    }

    isUploading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/teachers/import'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      });
      request.files.add(await http.MultipartFile.fromPath('file', excelFile!.path));

      var streamingStream = await request.send();
      var response = await http.Response.fromStream(streamingStream);

      dynamic parsedBody;
      try { parsedBody = jsonDecode(response.body); } catch (_) { parsedBody = null; }

      if (response.statusCode == 200) {
        showSnackBar("Dataset Synchronized", "Excel records populated inside database cluster smoothly.");
        selectedFilePath.value = '';
        excelFile = null;
        fetchTeachers();
      } else if (response.statusCode == 422) {
        String errorLog = parsedBody?['message'] ?? "Data alignment runtime validation failure.";
        if (parsedBody?['errors'] != null) {
          var validationTrack = parsedBody['errors'];
          if (validationTrack is Map) {
            validationTrack.forEach((k, v) => errorLog += "\n• ${(v is List) ? v.join(', ') : v}");
          }
        }
        _triggerCriticalModal("Validation Conflict (422)", errorLog);
      } else {
        _triggerCriticalModal("Server Error (${response.statusCode})", parsedBody?['message'] ?? "Internal processing fault.");
      }
    } catch (e) {
      _triggerCriticalModal("Transmission Exception", "Pipeline execution unexpected crush: $e");
    } finally {
      isUploading.value = false;
    }
  }

  // ================= EDIT / UPDATE RECORD =================
  Future<void> updateTeacher(int id, String name, String email, String password, String deptName) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: _getHeaders(),
        body: jsonEncode({
          'teacher_name': name,
          'email': email,
          if (password.isNotEmpty) 'password': password,
          'department_name': deptName,
        }),
      );

      dynamic body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        showSnackBar("Updated", "Teacher metadata attributes shifted inside schemas successfully.");
        fetchTeachers();
        Get.back();
      } else {
        showSnackBar("Mutation Refused", body['message'] ?? "Validation structure parsing mismatch.", isError: true);
      }
    } catch (e) {
      showSnackBar("Error", "Mutation payload transmission breakdown: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ================= DELETE TEACHER =================
  Future<void> deleteTeacher(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/teachers/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        showSnackBar("Dropped Record", "Identity structural links completely detached safely.");
        fetchTeachers();
      } else {
        showSnackBar("Erasure Terminated", "Could not execute removal pipelines context structural design.", isError: true);
      }
    } catch (e) {
      showSnackBar("Network Error", "Process execution failed: $e", isError: true);
    }
  }

  void showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title, message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent.withOpacity(0.8) : Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      barBlur: 10,
    );
  }

  void _triggerCriticalModal(String title, String msg) {
    showSnackBar(title, msg, isError: true);
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      content: SizedBox(
        height: 200, width: double.maxFinite,
        child: SingleChildScrollView(child: Text(msg, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
      ),
      textConfirm: "Acknowledge",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () => Get.back(),
    );
  }
}