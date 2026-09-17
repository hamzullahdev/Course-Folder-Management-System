import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class StudentController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  String authToken = "";

  var isLoading = false.obs;
  var isUploading = false.obs;
  var selectedFilePath = ''.obs;
  File? excelFile;

  var allStudents = <dynamic>[].obs;
  var filteredStudents = <dynamic>[].obs;

  var masterDepartments = <dynamic>[].obs;
  var masterPrograms = <dynamic>[].obs;
  var masterBatches = <dynamic>[].obs;

  var departments = <String>[].obs;
  var programs = <String>[].obs;
  var batches = <String>[].obs;
  final List<String> sections = ['A', 'B', 'C', 'D'];

  var selectedDepartment = ''.obs;
  var selectedProgram = ''.obs;
  var selectedBatch = ''.obs;
  var selectedSection = ''.obs;

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  void initializeData(String token) {
    authToken = token;
    fetchDropdownFilters();
    fetchStudents();
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
      debugPrint("JSON parsing exception: $e");
    }
    return [];
  }

  Future<void> fetchDropdownFilters() async {
    try {
      final deptRes = await http.get(Uri.parse('$baseUrl/department'), headers: _getHeaders()).timeout(const Duration(seconds: 15));
      if (deptRes.statusCode == 200) {
        masterDepartments.assignAll(_safeParseList(deptRes.body));
      }

      final progRes = await http.get(Uri.parse('$baseUrl/program'), headers: _getHeaders()).timeout(const Duration(seconds: 15));
      if (progRes.statusCode == 200) {
        masterPrograms.assignAll(_safeParseList(progRes.body));
      }

      final batchRes = await http.get(Uri.parse('$baseUrl/batches'), headers: _getHeaders()).timeout(const Duration(seconds: 15));
      if (batchRes.statusCode == 200) {
        masterBatches.assignAll(_safeParseList(batchRes.body));
      }

      _buildInitialDropdownStrings();
    } catch (e) {
      debugPrint("Error fetching dropdown filters: $e");
    }
  }

  void _buildInitialDropdownStrings() {
    List<String> depts = masterDepartments.map((e) => (e['dept_name'] ?? e['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();
    List<String> progs = masterPrograms.map((e) => (e['program_name'] ?? e['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();
    List<String> bths = masterBatches.map((e) => (e['batch_name'] ?? e['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();

    departments.assignAll(depts.toSet().toList());
    programs.assignAll(progs.toSet().toList());
    batches.assignAll(bths.toSet().toList());
  }

  void onDepartmentChanged(String? val) {
    selectedDepartment.value = (val ?? '').trim();
    selectedProgram.value = '';
    selectedBatch.value = '';

    if (selectedDepartment.value.isEmpty) {
      _buildInitialDropdownStrings();
    } else {
      var filteredProgs = masterPrograms.where((p) {
        return p['department'] != null &&
            (p['department']['name']?.toString().trim().toLowerCase() == selectedDepartment.value.toLowerCase() ||
                p['department']['dept_name']?.toString().trim().toLowerCase() == selectedDepartment.value.toLowerCase());
      }).map((p) => (p['program_name'] ?? p['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toSet().toList();

      programs.assignAll(List<String>.from(filteredProgs));
      batches.clear();
    }
    applyFilters();
  }

  void onProgramChanged(String? val) {
    selectedProgram.value = (val ?? '').trim();
    selectedBatch.value = '';

    if (selectedProgram.value.isEmpty) {
      onDepartmentChanged(selectedDepartment.value);
    } else {
      var filteredBths = masterBatches.where((b) {
        return b['program'] != null &&
            (b['program']['name']?.toString().trim().toLowerCase() == selectedProgram.value.toLowerCase() ||
                b['program']['program_name']?.toString().trim().toLowerCase() == selectedProgram.value.toLowerCase());
      }).map((b) => (b['batch_name'] ?? b['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toSet().toList();

      batches.assignAll(List<String>.from(filteredBths));
    }
    applyFilters();
  }

  void onBatchChanged(String? val) {
    selectedBatch.value = (val ?? '').trim();
    applyFilters();
  }

  void onSectionChanged(String? val) {
    selectedSection.value = (val ?? '').trim();
    applyFilters();
  }

  Future<void> browseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        // ✨ FIX 1: withData false kar diya taake mobile ki RAM full na ho aur app background mein crash na kare.
        withData: false,
      );

      if (result != null && result.files.single.path != null) {
        selectedFilePath.value = result.files.single.path!;
        excelFile = File(result.files.single.path!);
      } else {
        showSnackBar("Cancelled", "File selection was cancelled", isError: true);
      }
    } catch (e) {
      showSnackBar("Error", "Failed to pick file: $e", isError: true);
    }
  }

  Future<void> importExcel() async {
    if (excelFile == null) {
      showSnackBar("Warning", "Please select an Excel or CSV file first.", isError: true);
      return;
    }

    isUploading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/students/import'));
      request.headers.addAll(_getHeaders());
      request.files.add(await http.MultipartFile.fromPath('file', excelFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = null;
      }

      if (response.statusCode == 200) {
        String successMsg = (responseData != null && responseData['message'] != null)
            ? responseData['message']
            : "Excel spreadsheet datasets imported successfully.";
        showSnackBar("Success", successMsg);
        selectedFilePath.value = '';
        excelFile = null;
        fetchStudents();
      } else if (response.statusCode == 422) {
        String errorMsg = (responseData != null && responseData['message'] != null)
            ? responseData['message']
            : "Data validation errors occurred during import.";

        if (responseData != null && responseData['errors'] != null) {
          errorMsg += "\n";
          var validationErrors = responseData['errors'];

          if (validationErrors is Map) {
            validationErrors.forEach((key, value) {
              if (value is List) {
                errorMsg += "\n• ${value.join(', ')}";
              } else {
                errorMsg += "\n• $value";
              }
            });
          } else if (validationErrors is List) {
            errorMsg += "\n" + validationErrors.join("\n");
          }
        }
        _showCriticalError("Validation Error (422)", errorMsg);
      } else {
        String genericError = (responseData != null && responseData['message'] != null)
            ? responseData['message']
            : "Internal application server error occurred.";
        _showCriticalError("Server Error (${response.statusCode})", genericError);
      }
    } catch (e) {
      _showCriticalError("Pipeline Exception", "Transmission exception: $e");
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> fetchStudents() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/students'), headers: _getHeaders()).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        List<dynamic> rawList = _safeParseList(response.body);

        var normalizedList = rawList.map((student) {
          if (student['program'] != null) {
            student['program']['name'] = student['program']['program_name'] ?? student['program']['name'];
          }
          if (student['batch'] != null) {
            student['batch']['name'] = student['batch']['batch_name'] ?? student['batch']['name'];
          }

          // ✨ FIX 2: Enrollment relation se Section nikal kar ek naya variable 'section_display' bana diya
          String sectionDisplay = 'N/A';
          if (student['enrollments'] != null && (student['enrollments'] as List).isNotEmpty) {
            var sections = (student['enrollments'] as List)
                .map((e) => (e['section'] ?? '').toString().trim())
                .where((s) => s.isNotEmpty && s != 'null')
                .toSet()
                .toList();

            if (sections.isNotEmpty) {
              sectionDisplay = sections.join(', ');
            }
          }
          // Ye key ab aap UI Grid mein use kar sakte hain
          student['section_display'] = sectionDisplay;

          return student;
        }).toList();

        allStudents.assignAll(normalizedList);
        applyFilters();
      } else {
        showSnackBar("Error", "Failed to load students layout dataset.", isError: true);
      }
    } catch (e) {
      showSnackBar("Error", "Connection pipeline failed: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    if (allStudents.isEmpty) {
      filteredStudents.clear();
      return;
    }

    var tempGridList = allStudents.where((student) {
      bool matchesDepartment = selectedDepartment.value.isEmpty;
      if (selectedDepartment.value.isNotEmpty) {
        String rootDept = (student['department']?['name'] ?? student['department']?['dept_name'] ?? '').toString().trim();
        String nestedDept = (student['program']?['department']?['name'] ?? student['program']?['department']?['dept_name'] ?? '').toString().trim();

        matchesDepartment = (rootDept.toLowerCase() == selectedDepartment.value.toLowerCase()) ||
            (nestedDept.toLowerCase() == selectedDepartment.value.toLowerCase());
      }

      bool matchesProgram = selectedProgram.value.isEmpty;
      if (selectedProgram.value.isNotEmpty && student['program'] != null) {
        String progName = (student['program']['name'] ?? student['program']['program_name'] ?? '').toString().trim();
        matchesProgram = (progName.toLowerCase() == selectedProgram.value.toLowerCase());
      }

      bool matchesBatch = selectedBatch.value.isEmpty;
      if (selectedBatch.value.isNotEmpty && student['batch'] != null) {
        String batchName = (student['batch']['name'] ?? student['batch']['batch_name'] ?? '').toString().trim();
        matchesBatch = (batchName.toLowerCase() == selectedBatch.value.toLowerCase());
      }

      bool matchesSection = selectedSection.value.isEmpty;
      if (selectedSection.value.isNotEmpty && student['enrollments'] != null) {
        var enrollments = student['enrollments'] as List;
        matchesSection = enrollments.any((enrollment) {
          String sec = (enrollment['section'] ?? '').toString().trim();
          return sec.toLowerCase() == selectedSection.value.toLowerCase();
        });
      }

      return matchesDepartment && matchesProgram && matchesBatch && matchesSection;
    }).toList();

    filteredStudents.assignAll(tempGridList);
  }

  void clearFilters() {
    selectedDepartment.value = '';
    selectedProgram.value = '';
    selectedBatch.value = '';
    selectedSection.value = '';
    fetchDropdownFilters();
    fetchStudents();
  }

  Future<void> deleteStudent(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/students/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        showSnackBar("Deleted", "Student record dropped successfully.");
        fetchStudents();
      } else {
        showSnackBar("Error", "Failed to delete student record.", isError: true);
      }
    } catch (e) {
      showSnackBar("Error", "Could not execute deletion pipeline: $e", isError: true);
    }
  }

  void _showCriticalError(String title, String message) {
    showSnackBar(title, message, isError: true);
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      content: Container(
        height: 250,
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      radius: 10,
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () => Get.back(),
    );
  }

  void showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }
}