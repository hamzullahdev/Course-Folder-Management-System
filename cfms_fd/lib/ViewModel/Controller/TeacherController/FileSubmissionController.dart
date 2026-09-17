import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class FileSubmissionController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;
  final String allocationId;

  FileSubmissionController({required this.token, required this.allocationId});

  var folders = <dynamic>[].obs;
  var files = <dynamic>[].obs;
  var uploadedSubmissions = <dynamic>[].obs;

  var selectedFolderId = ''.obs;
  var selectedFileId = ''.obs;

  var selectedFilePath = ''.obs;
  var selectedFileName = ''.obs;

  var isLoading = false.obs;
  var isUploading = false.obs;
  var isEditMode = false.obs; // ✨ Track edit mode to allow re-upload

  @override
  void onInit() {
    super.onInit();
    fetchFolders();
    fetchSubmissions();
  }

  Future<void> fetchFolders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/folders'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        folders.assignAll(data['data'] ?? []);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load folders.");
    }
  }

  Future<void> fetchFilesByFolder(String folderId) async {
    selectedFileId.value = '';
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/folders/$folderId/files'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        files.assignAll(data['data'] ?? []);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load files.");
    }
  }

  Future<void> fetchSubmissions() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/teacher/allocations/$allocationId/submissions'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        uploadedSubmissions.assignAll(data['data'] ?? []);
        uploadedSubmissions.refresh(); // ✨ Refreshing UI Grid
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load submissions.");
    } finally {
      isLoading.value = false;
    }
  }

  // ✨ Helper to replace browsed file name with Dropdown Name
  void updateFileNameDisplay() {
    if (selectedFilePath.value.isNotEmpty && selectedFileId.value.isNotEmpty) {
      var selectedFile = files.firstWhere(
              (f) => (f['file_id']?.toString() ?? f['id']?.toString()) == selectedFileId.value,
          orElse: () => null
      );
      if (selectedFile != null) {
        String ext = selectedFilePath.value.split('.').last;
        selectedFileName.value = "${selectedFile['file_name'] ?? 'Document'}.$ext";
      }
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      selectedFilePath.value = result.files.single.path!;
      selectedFileName.value = result.files.single.name;
      updateFileNameDisplay();
    }
  }

  Future<void> uploadDocument() async {
    if (selectedFileId.value.isEmpty || selectedFilePath.value.isEmpty) {
      Get.snackbar("Warning", "Please select a file type and browse a document.", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // ✨ Duplicate check
    if (!isEditMode.value) {
      bool alreadyExists = uploadedSubmissions.any((sub) => (sub['file_id']?.toString() ?? sub['id']?.toString()) == selectedFileId.value);
      if (alreadyExists) {
        Get.snackbar("Already Uploaded", "This file is already uploaded. Use Edit icon to re-upload.", backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 4));
        return;
      }
    }

    isUploading.value = true;
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/teacher/submissions/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['course_allocation_id'] = allocationId;
      request.fields['file_id'] = selectedFileId.value;

      request.files.add(await http.MultipartFile.fromPath('document', selectedFilePath.value));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Get.snackbar("Success", "File uploaded successfully!", backgroundColor: Colors.green, colorText: Colors.white);
        selectedFilePath.value = '';
        selectedFileName.value = '';
        isEditMode.value = false;
        fetchSubmissions();
      } else {
        var errorData = json.decode(response.body);
        String errorMessage = "Error uploading file.";
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
        Get.snackbar("Upload Failed", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
      }
    } catch (e) {
      Get.snackbar("Exception", "Network issue during upload. Check console.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isUploading.value = false;
    }
  }

  void triggerEditMode(String fileId) {
    isEditMode.value = true;
    selectedFileId.value = fileId;
    pickFile();
  }
}