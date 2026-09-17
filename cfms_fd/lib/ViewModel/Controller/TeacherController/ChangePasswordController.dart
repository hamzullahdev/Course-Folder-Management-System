import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ChangePasswordController extends GetxController {
  final String baseUrl = "http://127.0.0.1:8000/api";
  final String token;

  ChangePasswordController({required this.token});

  var isLoading = false.obs;

  Future<bool> updatePassword(String currentPassword, String newPassword, String confirmPassword) async {
    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Success",
          data['message'] ?? "Password updated successfully.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to update password.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Network Error",
        "Failed to connect to the server. Please check your connection.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}