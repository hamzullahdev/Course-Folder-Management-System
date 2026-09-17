import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FcarController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api/teacher";
  String authToken = "";

  var allocations = <dynamic>[].obs;
  var isLoadingAllocations = false.obs;
  var isGenerating = false.obs;
  var selectedAllocationId = ''.obs;

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  void initializeData(String token) {
    authToken = token;
    fetchAllocations();
  }

  Future<void> fetchAllocations() async {
    isLoadingAllocations.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/fcar/allocations'), headers: _getHeaders());
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          allocations.assignAll(jsonData['allocations']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching FCAR allocations: $e");
    } finally {
      isLoadingAllocations.value = false;
    }
  }

  Future<void> generateReport() async {
    if (selectedAllocationId.value.isEmpty) return;

    isGenerating.value = true;
    try {
      // Backend ko request bhejein PDF generate karne ke liye
      final response = await http.post(
        Uri.parse('$baseUrl/fcar/generate'),
        headers: _getHeaders()..addAll({'Content-Type': 'application/json'}),
        body: json.encode({'allocation_id': selectedAllocationId.value}),
      );

      if (response.statusCode == 200) {
        // Filename Backend ke Header se nikalna (Course Name - Course Code.pdf)
        String fileName = "FCAR_Report.pdf"; // Fallback name
        String? contentDisposition = response.headers['content-disposition'];

        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          fileName = contentDisposition.split('filename=')[1].replaceAll('"', '');
        }

        // Android ke native Downloads folder mein save karna
        Directory dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir.createSync(recursive: true);
        }

        File file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Success message jo aapne manga tha
        Get.snackbar(
          "Success",
          "FCAR Generated successfully.\nSaved in Downloads: $fileName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar("Error", "Failed to generate report.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Network error occurred. $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isGenerating.value = false;
    }
  }
}