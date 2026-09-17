import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CourseOfferedController extends GetxController {
  // Update this to your actual local machine IP if testing on a physical device
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // UI State Flags
  var isLoading = false.obs;
  var isUploading = false.obs;
  var selectedFilePath = ''.obs;

  // Selected Filter Values
  var selectedDepartment = ''.obs;
  var selectedProgram = ''.obs;
  var selectedSession = ''.obs;

  // Raw Data Lists
  var departmentsList = <Map<String, dynamic>>[].obs;
  var programsList = <Map<String, dynamic>>[].obs;

  // NEW: Filtered list for dependent dropdown
  var filteredProgramsList = <Map<String, dynamic>>[].obs;
  var sessionsList = <Map<String, dynamic>>[].obs;

  var allOfferedCourses = <Map<String, dynamic>>[].obs;
  var filteredOfferedCourses = <Map<String, dynamic>>[].obs;

  String _authToken = "";

  void initializeData(String token) {
    _authToken = token;
    fetchDropdownFilters();
    fetchOfferedCourses();
  }

  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // --- Fetch Dropdown Data ---
  Future<void> fetchDropdownFilters() async {
    try {
      final headers = _getHeaders();

      final deptRes = await http.get(Uri.parse('$baseUrl/admin/department'), headers: headers);
      if (deptRes.statusCode == 200) {
        var decoded = jsonDecode(deptRes.body);
        departmentsList.assignAll(List<Map<String, dynamic>>.from(decoded['data'] ?? decoded));
      }

      final progRes = await http.get(Uri.parse('$baseUrl/admin/program'), headers: headers);
      if (progRes.statusCode == 200) {
        var decoded = jsonDecode(progRes.body);
        var progs = List<Map<String, dynamic>>.from(decoded['data'] ?? decoded);
        programsList.assignAll(progs);
        // Initially populate filtered list with all programs
        filteredProgramsList.assignAll(progs);
      }

      final sessRes = await http.get(Uri.parse('$baseUrl/admin/sessions'), headers: headers);
      if (sessRes.statusCode == 200) {
        var decoded = jsonDecode(sessRes.body);
        sessionsList.assignAll(List<Map<String, dynamic>>.from(decoded['data'] ?? decoded));
      }
    } catch (e) {
      Get.snackbar("Sync Error", "Failed to load dropdown data: $e");
    }
  }

  // --- Fetch Grid Data ---
  Future<void> fetchOfferedCourses() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/course-offered'), headers: _getHeaders());

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          allOfferedCourses.assignAll(List<Map<String, dynamic>>.from(decoded['data']));
          applyFilters();
        }
      } else {
        Get.snackbar("Fetch Error", "Failed to fetch courses data.");
      }
    } catch (e) {
      Get.snackbar("Network Error", "Could not connect to the server.");
    } finally {
      isLoading.value = false;
    }
  }

  // --- Dynamic Filter Logic ---
  void applyFilters() {
    var results = allOfferedCourses.where((item) {
      var course = item['course'];
      var program = course?['program'];
      var session = item['session'];

      // Safely map values, providing fallbacks if nested relations are missing
      String currentProg = program?['program_name'] ?? '';
      String currentSess = session?['s_name'] ?? '';

      // Safely extract department. Handling both nested object or flattened string
      String currentDept = '';
      if (program != null) {
        currentDept = program['department']?['dept_name'] ?? program['dept_name'] ?? '';
      }

      bool matchesDept = selectedDepartment.value.isEmpty || currentDept == selectedDepartment.value;
      bool matchesProg = selectedProgram.value.isEmpty || currentProg == selectedProgram.value;
      bool matchesSess = selectedSession.value.isEmpty || currentSess == selectedSession.value;

      return matchesDept && matchesProg && matchesSess;
    }).toList();

    filteredOfferedCourses.assignAll(results);
  }

  void onFilterChanged(String type, String? value) {
    String safeValue = value ?? '';

    if (type == 'dept') {
      selectedDepartment.value = safeValue;

      // Department change hone par Program ko reset karna zaroori hai
      selectedProgram.value = '';

      // Filter dependent programs
      if (safeValue.isEmpty) {
        filteredProgramsList.assignAll(programsList);
      } else {
        filteredProgramsList.assignAll(programsList.where((p) {
          String deptName = p['department']?['dept_name'] ?? p['dept_name'] ?? '';
          return deptName == safeValue;
        }).toList());
      }
    }
    else if (type == 'prog') {
      selectedProgram.value = safeValue;
    }
    else if (type == 'sess') {
      // Session is fully independent
      selectedSession.value = safeValue;
    }

    // Har dropdown change par grid filter update hoga
    applyFilters();
  }

  // --- File Selection ---
  Future<void> browseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        selectedFilePath.value = result.files.single.path!;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick file.");
    }
  }

  // --- Import API ---
  Future<void> importExcel() async {
    if (selectedFilePath.value.isEmpty) {
      Get.snackbar("Validation", "Please select an Excel file first.");
      return;
    }

    isUploading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/course-offered/import'));
      request.headers.addAll({'Authorization': 'Bearer $_authToken', 'Accept': 'application/json'});
      request.files.add(await http.MultipartFile.fromPath('file', selectedFilePath.value));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonBody['success'] == true) {
        Get.snackbar("Success", jsonBody['message']);
        selectedFilePath.value = '';
        fetchOfferedCourses();
      } else {
        Get.snackbar("Import Failed", jsonBody['message'] ?? "Check your template format.");
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred during import.");
    } finally {
      isUploading.value = false;
    }
  }

  // --- Delete API ---
  Future<void> deleteCourse(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/course-offered/$id'),
        headers: _getHeaders(),
      );
      var jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonBody['success'] == true) {
        Get.snackbar("Success", jsonBody['message']);
        allOfferedCourses.removeWhere((item) => item['id'] == id);
        applyFilters();
      } else {
        Get.snackbar("Error", jsonBody['message'] ?? "Failed to delete record.");
      }
    } catch (e) {
      Get.snackbar("Error", "Network issue while deleting.");
    }
  }
}