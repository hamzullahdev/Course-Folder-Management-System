import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FilesController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  // ✨ FIX 1: Token variable aur Headers ka function
  String authToken = "";

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  var allFiles = <dynamic>[].obs;
  var filteredFiles = <dynamic>[].obs;
  var validFolders = <dynamic>[].obs;

  var isLoading = false.obs;
  var isAdding = false.obs;

  // Selected Folder Dropdown Value
  var selectedFolderId = ''.obs;

  // Input Controller
  final TextEditingController fileNameController = TextEditingController();

  // ✨ FIX 2: Screen se Token receive karne ke liye initializeData
  void initializeData(String token) {
    authToken = token;
    fetchData(); // Token set hone ke baad hi data fetch hoga
  }

  @override
  void onInit() {
    super.onInit();
    // ✨ FIX 3: Yahan se fetchData() hata diya gaya hai taake bina token hit na ho
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    await fetchValidFolders();
    await fetchFiles();
    isLoading.value = false;
  }

  // Fetch folders where no_of_files > 0
  Future<void> fetchValidFolders() async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.get(Uri.parse('$baseUrl/valid-file-folders'), headers: _getHeaders());
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          validFolders.assignAll(jsonData['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching valid folders: $e");
    }
  }

  // Fetch all files
  Future<void> fetchFiles() async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.get(Uri.parse('$baseUrl/files'), headers: _getHeaders());
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          allFiles.assignAll(jsonData['data'] ?? []);
          applyFilter(); // Apply filter automatically after loading
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load files.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Dynamic filter logic: Grid only shows files of the selected folder
  void applyFilter() {
    if (selectedFolderId.value.isEmpty) {
      filteredFiles.assignAll([]); // If no folder selected, grid remains empty
    } else {
      var filtered = allFiles.where((f) => f['folder_id'].toString() == selectedFolderId.value).toList();
      filteredFiles.assignAll(filtered);
    }
  }

  Future<void> addFile() async {
    String name = fileNameController.text.trim();
    String folderId = selectedFolderId.value;

    if (folderId.isEmpty) {
      Get.snackbar("Validation", "Please select a Folder first.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }
    if (name.isEmpty) {
      Get.snackbar("Validation", "File Name cannot be empty.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    isAdding.value = true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/files'),
        // ✨ FIX 4: _getHeaders() ke sath Content-Type merge kiya
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode({
          "file_name": name,
          "folder_id": int.parse(folderId),
        }),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar("Success", "File created successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        fileNameController.clear();
        await fetchFiles(); // Refresh grid with new data
      } else {
        String errorMessage = responseData['errors']?['file_name']?[0] ?? responseData['message'] ?? "Failed to create.";
        Get.snackbar("Error", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Network error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isAdding.value = false;
    }
  }

  Future<void> deleteFile(int id) async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.delete(Uri.parse('$baseUrl/files/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        Get.snackbar("Deleted", "File deleted cleanly.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchFiles();
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  Future<void> updateFile(int id, Map<String, dynamic> payload) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/files/$id'),
        // ✨ FIX 4: _getHeaders() ke sath Content-Type merge kiya
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        Get.snackbar("Updated", "File updated successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchFiles();
      } else {
        var data = json.decode(response.body);
        String err = data['errors']?['file_name']?[0] ?? "Update error";
        Get.snackbar("Failed", err, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}