import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SubFolderController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  // ✨ FIX 1: Token variable aur Headers ka function
  String authToken = "";

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  var allSubFolders = <dynamic>[].obs;
  var validParents = <dynamic>[].obs;

  var isLoading = false.obs;
  var isAdding = false.obs;

  // Selected Parent Folder ID
  var selectedParentId = ''.obs;

  // Input Controllers
  final TextEditingController subFolderNameController = TextEditingController();
  final TextEditingController noOfFilesController = TextEditingController();

  // ✨ FIX 2: Screen se Token receive karne ke liye initializeData
  void initializeData(String token) {
    authToken = token;
    fetchData(); // Token set hone ke baad API call ho
  }

  @override
  void onInit() {
    super.onInit();
    // ✨ FIX 3: Yahan se fetchData() hata diya gaya hai taake bina token ke API hit na ho
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    await fetchValidParents();
    await fetchSubFolders();
    isLoading.value = false;
  }

  // Fetch folders with no_of_files == 0
  Future<void> fetchValidParents() async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.get(Uri.parse('$baseUrl/parent-folders'), headers: _getHeaders());
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          validParents.assignAll(jsonData['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching parent folders: $e");
    }
  }

  // Fetch sub-folders for the grid
  Future<void> fetchSubFolders() async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.get(Uri.parse('$baseUrl/subfolders'), headers: _getHeaders());
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          allSubFolders.assignAll(jsonData['data'] ?? []);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load sub-folders.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> addSubFolder() async {
    String name = subFolderNameController.text.trim();
    String filesCount = noOfFilesController.text.trim();
    String parentId = selectedParentId.value;

    if (parentId.isEmpty) {
      Get.snackbar("Validation", "Please select a Parent Folder first.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }
    if (name.isEmpty) {
      Get.snackbar("Validation", "Sub Folder Name cannot be empty.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    isAdding.value = true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subfolders'),
        // ✨ FIX 4: _getHeaders() ke sath Content-Type merge kiya
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode({
          "folder_name": name,
          "no_of_files": filesCount.isEmpty ? 0 : int.tryParse(filesCount) ?? 0,
          "parent_id": int.parse(parentId),
        }),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Sub-folder created successfully.", backgroundColor: Colors.green, colorText: Colors.white);
        subFolderNameController.clear();
        noOfFilesController.clear();
        selectedParentId.value = '';

        await fetchData(); // Refresh both dropdown and grid
      } else {
        String errorMessage = responseData['errors']?['folder_name']?[0] ?? responseData['message'] ?? "Failed to create.";
        Get.snackbar("Error", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Network error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isAdding.value = false;
    }
  }

  Future<void> deleteSubFolder(int id) async {
    try {
      // ✨ FIX 4: Headers add kiye
      final response = await http.delete(Uri.parse('$baseUrl/subfolders/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        Get.snackbar("Deleted", "Sub-folder deleted cleanly.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchData();
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  Future<void> updateSubFolder(int id, Map<String, dynamic> payload) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subfolders/$id'),
        // ✨ FIX 4: _getHeaders() ke sath Content-Type merge kiya
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        Get.snackbar("Updated", "Sub-folder updated.", backgroundColor: Colors.green, colorText: Colors.white);
        fetchData();
      } else {
        var data = json.decode(response.body);
        Get.snackbar("Failed", data['message'] ?? "Update error", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}