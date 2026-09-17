import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ViewClosController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;

  ViewClosController({required this.token});

  var allocations = <dynamic>[].obs;
  var closList = <dynamic>[].obs;
  var isLoading = false.obs;

  // Reusing the endpoint to fetch Teacher's allocated courses
  Future<void> fetchAllocations() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/my-courses'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        allocations.assignAll(json.decode(response.body)['data']);
      }
    } catch (e) {
      debugPrint("Error fetching allocations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch CLOs for the selected Course ID
  Future<void> fetchClosByCourse(String courseId) async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/course/$courseId/clos'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        closList.assignAll(json.decode(response.body)['data']);
      } else {
        closList.clear();
      }
    } catch (e) {
      debugPrint("Error fetching CLOs: $e");
      closList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}