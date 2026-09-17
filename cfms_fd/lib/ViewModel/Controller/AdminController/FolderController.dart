import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FolderController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/admin";

  // 1. Token variable
  String authToken = "";

  // 2. Har API request ke sath token bhejne ka function
  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  var allFolders = <dynamic>[].obs;
  var isLoading = false.obs;
  var isAdding = false.obs;

  // Input Controllers for adding new folder
  final TextEditingController folderNameController = TextEditingController();
  final TextEditingController noOfFilesController = TextEditingController();

  void initializeData(String token) {
    authToken = token;
    fetchFolders();
  }

  @override
  void onInit() {
    super.onInit();
    // Fetch yahan se hata diya gaya hai (Perfect!)
  }

  // Fetch all folders from API
  Future<void> fetchFolders() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/folders'), headers: _getHeaders());

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          allFolders.assignAll(jsonData['data']);
        }
      } else {
        Get.snackbar("Error", "Failed to load folders from database.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Network or parsing error occurred.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new folder
  Future<void> addFolder() async {
    String name = folderNameController.text.trim();
    String filesCount = noOfFilesController.text.trim();

    if (name.isEmpty) {
      Get.snackbar("Validation", "Folder Name cannot be empty.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    isAdding.value = true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/folders'),
        // ✨ FIX: _getHeaders() ke sath Content-Type ko merge kiya!
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode({
          "folder_name": name,
          "no_of_files": filesCount.isEmpty ? 0 : int.tryParse(filesCount) ?? 0,
        }),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Folder created successfully.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);

        // Clear inputs after success
        folderNameController.clear();
        noOfFilesController.clear();

        fetchFolders(); // Refresh grid
      } else {
        String errorMessage = "Failed to create folder.";
        if (responseData['errors'] != null && responseData['errors']['folder_name'] != null) {
          errorMessage = responseData['errors']['folder_name'][0]; // Catch unique name error
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }

        Get.snackbar("Error", errorMessage,
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Network error while saving folder.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isAdding.value = false;
    }
  }

  // Delete a folder
  Future<void> deleteFolder(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/folders/$id'), headers: _getHeaders());
      if (response.statusCode == 200) {
        Get.snackbar("Deleted", "Folder and its contents removed cleanly.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchFolders();
      } else {
        Get.snackbar("Error", "Failed to delete folder.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Action failed due to network error.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Update a folder
  Future<void> updateFolder(int id, Map<String, dynamic> updatePayload) async {
    isLoading.value = true;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/folders/$id'),
        // ✨ FIX: _getHeaders() ke sath Content-Type ko merge kiya!
        headers: _getHeaders()..addAll({"Content-Type": "application/json"}),
        body: json.encode(updatePayload),
      );

      var responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar("Updated", "Folder attributes updated accurately.",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchFolders();
      } else {
        String errorMessage = "Failed to update folder.";
        if (responseData['errors'] != null && responseData['errors']['folder_name'] != null) {
          errorMessage = responseData['errors']['folder_name'][0];
        }
        Get.snackbar("Update Failed", errorMessage,
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Action failed due to network error.",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}