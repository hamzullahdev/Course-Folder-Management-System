import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CourseAllocationController extends GetxController {
  // ⚠️ NOTE: Update to your local IP if running on physical device
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  // ✨ FIX: Token aur Headers ka setup add kiya gaya hai
  String authToken = "";

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  var allAllocations = <dynamic>[].obs;
  var filteredAllocations = <dynamic>[].obs;
  var isLoading = false.obs;
  var filePathDisplay = ''.obs;
  File? selectedFile;

  // Raw Database Backups for Safe Cascading Logic
  var rawDepartments = <dynamic>[].obs;
  var rawPrograms = <dynamic>[].obs;

  // Filter Dropdown Lists
  var departments = <String>[].obs;
  var programs = <String>[].obs;
  var allProgramsFromApi = <String>[].obs; // Safe backup
  var sessions = <String>[].obs;
  var batches = <String>[].obs;
  var sections = <String>[].obs;

  // Selected Filter Values
  var selectedDept = ''.obs;
  var selectedProg = ''.obs;
  var selectedSess = ''.obs;
  var selectedBatch = ''.obs;
  var selectedSec = ''.obs;

  // ✨ FIX: UI se Token receive karne ke liye initializeData banaya gaya hai
  void initializeData(String token) {
    authToken = token;
    fetchDropdownData();
    fetchAllocations();
  }

  @override
  void onInit() {
    super.onInit();
    // Direct fetch hataya taake pehle Token set ho
  }

  // Safe JSON extraction helper
  List<dynamic> _extractDataArray(String responseBody) {
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
      // ✨ FIX: Har API call mein headers: _getHeaders() add kiya
      // 1. Fetch Departments
      var deptRes = await http.get(Uri.parse('$baseUrl/department'), headers: _getHeaders());
      if (deptRes.statusCode == 200) {
        var data = _extractDataArray(deptRes.body);
        rawDepartments.assignAll(data);
        departments.assignAll(data.map((e) => e['dept_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList().cast<String>());
      }

      // 2. Fetch Programs
      var progRes = await http.get(Uri.parse('$baseUrl/program'), headers: _getHeaders());
      if (progRes.statusCode == 200) {
        var data = _extractDataArray(progRes.body);
        rawPrograms.assignAll(data);
        var progs = data.map((e) => e['program_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList().cast<String>();

        programs.assignAll(progs);
        allProgramsFromApi.assignAll(progs);
      }

      // 3. Fetch Sessions
      var sessRes = await http.get(Uri.parse('$baseUrl/sessions'), headers: _getHeaders());
      if (sessRes.statusCode == 200) {
        var data = _extractDataArray(sessRes.body);
        sessions.assignAll(data.map((e) => e['s_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList().cast<String>());
      }

      // 4. Fetch Batches
      var batchRes = await http.get(Uri.parse('$baseUrl/batches'), headers: _getHeaders());
      if (batchRes.statusCode == 200) {
        var data = _extractDataArray(batchRes.body);
        batches.assignAll(data.map((e) => e['batch_name']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList().cast<String>());
      }
    } catch (e) {
      debugPrint("❌ Exception fetching dropdown master data: $e");
    }
  }

  // Fetch all course allocations for grid mapping
  Future<void> fetchAllocations() async {
    isLoading.value = true;
    try {
      // ✨ FIX: Headers add kiye
      final response = await http.get(Uri.parse('$baseUrl/course-allocations'), headers: _getHeaders());

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          allAllocations.assignAll(jsonData['data']);
          populateSectionFilter();
          applyFilters();
        }
      } else {
        Get.snackbar("Error", "Failed to load records from database.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("❌ Exception caught inside fetchAllocations: $e");
      Get.snackbar("Exception", "Network or parsing error occurred.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Extract unique sections dynamically from allocations ledger
  void populateSectionFilter() {
    try {
      var secSet = allAllocations
          .map((e) => e['section']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      sections.assignAll(secSet.toList().cast<String>());
    } catch (e) {
      debugPrint("❌ Error extracting sections mapping: $e");
    }
  }

  // ================= 100% CRASH-PROOF CASCADING LOGIC =================
  void handleDepartmentChange(String newDept) {
    selectedProg.value = ''; // Reset program

    if (newDept.isEmpty) {
      programs.assignAll(allProgramsFromApi); // All departments selected, show all programs
    } else {
      String foundDeptId = '';

      // Safe For-Loop mapping (Crash-Proof)
      for (var d in rawDepartments) {
        if ((d['dept_name']?.toString() ?? '') == newDept) {
          foundDeptId = d['id'].toString();
          break;
        }
      }

      if (foundDeptId.isNotEmpty) {
        List<String> validPrograms = [];
        for (var p in rawPrograms) {
          if (p['department_id'].toString() == foundDeptId) {
            String pName = p['program_name']?.toString() ?? '';
            if (pName.isNotEmpty) validPrograms.add(pName);
          }
        }
        programs.assignAll(validPrograms.toSet().toList());
      } else {
        programs.assignAll([]);
      }
    }

    applyFilters();
  }

  // Evaluate mapping attributes for UI grid rendering
  void applyFilters() {
    var intermediateList = allAllocations.where((item) {
      // ⚠️ Make sure backend API is updated to return '.department' relation
      String d = item['course_offered']?['course']?['program']?['department']?['dept_name']?.toString() ?? '';
      String p = item['course_offered']?['course']?['program']?['program_name']?.toString() ?? '';
      String ss = item['session']?['s_name']?.toString() ?? '';
      String b = item['batch']?['batch_name']?.toString() ?? '';
      String sc = item['section']?.toString() ?? '';

      bool matchesDept = selectedDept.value.isEmpty || d == selectedDept.value;
      bool matchesProg = selectedProg.value.isEmpty || p == selectedProg.value;
      bool matchesSess = selectedSess.value.isEmpty || ss == selectedSess.value;
      bool matchesBatch = selectedBatch.value.isEmpty || b == selectedBatch.value;
      bool matchesSec  = selectedSec.value.isEmpty || sc == selectedSec.value;

      return matchesDept && matchesProg && matchesSess && matchesBatch && matchesSec;
    }).toList();

    filteredAllocations.assignAll(intermediateList);
  }

  // Handle local excel file browsing operation
  Future<void> browseExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: false, // ✨ FIX: Memory crash se bachne ke liye lazmi hai
    );

    if (result != null && result.files.single.path != null) {
      selectedFile = File(result.files.single.path!);
      filePathDisplay.value = result.files.single.name;
    } else {
      Get.snackbar("Cancelled", "File browsing operation was cancelled.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orangeAccent, colorText: Colors.white);
    }
  }

  // Upload spreadsheet to backend
  Future<void> importSpreadsheet() async {
    if (selectedFile == null) {
      Get.snackbar("Warning", "Please browse and select a valid document file first.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.amber, colorText: Colors.black);
      return;
    }

    isLoading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/course-allocations/import'));
      request.headers.addAll(_getHeaders()); // ✨ FIX: Multipart Request mein headers add kiye
      request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar("Success", responseData['message'] ?? "Data processed completely.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        filePathDisplay.value = '';
        selectedFile = null;

        // Refresh API Dropdowns & Grid
        await fetchDropdownData();
        await fetchAllocations();
      } else {
        String realErrorMessage = responseData['error'] ?? responseData['message'] ?? "Unknown backend error occurred.";
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

  Future<void> deleteAllocation(int id) async {
    try {
      // ✨ FIX: Headers add kiye
      final response = await http.delete(Uri.parse('$baseUrl/course-allocations/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        Get.snackbar("Deleted", "Allocation record removed cleanly.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchAllocations();
      }
    } catch (e) {
      Get.snackbar("Exception", "Failed to reach server.");
    }
  }

  Future<void> updateAllocation(int id, Map<String, dynamic> updatePayload) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/course-allocations/$id'),
        // ✨ FIX: Headers merge kiye
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode(updatePayload),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Updated", "Allocation updated accurately.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchAllocations();
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