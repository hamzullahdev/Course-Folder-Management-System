import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/TeacherController/ChangePasswordController.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String token;
  const ChangePasswordScreen({super.key, required this.token});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late ChangePasswordController controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChangePasswordController(token: widget.token));
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData prefixIcon, bool isObscured, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(prefixIcon, color: Colors.white70),
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility_off : Icons.visibility,
          color: Colors.white70,
        ),
        onPressed: toggleVisibility,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      errorStyle: const TextStyle(color: Colors.orangeAccent),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.lock_reset, size: 80, color: Colors.white70),
                  const SizedBox(height: 20),
                  const Text(
                    "Update Account Password",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please ensure your new password is at least 8 characters long to stay secure.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // --- GLASSMORPHISM FORM PANEL ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Current Password
                              TextFormField(
                                controller: _currentPassCtrl,
                                style: const TextStyle(color: Colors.white),
                                obscureText: _obscureCurrent,
                                decoration: _inputDeco(
                                    "Current Password",
                                    Icons.lock_outline,
                                    _obscureCurrent,
                                        () => setState(() => _obscureCurrent = !_obscureCurrent)
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Current password is required.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 2. New Password
                              TextFormField(
                                controller: _newPassCtrl,
                                style: const TextStyle(color: Colors.white),
                                obscureText: _obscureNew,
                                decoration: _inputDeco(
                                    "New Password",
                                    Icons.lock_reset_outlined,
                                    _obscureNew,
                                        () => setState(() => _obscureNew = !_obscureNew)
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'New password is required.';
                                  if (val.trim().length < 8) return 'Password must be at least 8 characters.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Confirm New Password
                              TextFormField(
                                controller: _confirmPassCtrl,
                                style: const TextStyle(color: Colors.white),
                                obscureText: _obscureConfirm,
                                decoration: _inputDeco(
                                    "Confirm New Password",
                                    Icons.check_circle_outline,
                                    _obscureConfirm,
                                        () => setState(() => _obscureConfirm = !_obscureConfirm)
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Please confirm your new password.';
                                  if (val.trim() != _newPassCtrl.text.trim()) return 'Passwords do not match.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 35),

                              // 4. SAVE BUTTON
                              Obx(() => SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F51B5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 5,
                                  ),
                                  onPressed: controller.isLoading.value ? null : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // Remove keyboard
                                      FocusScope.of(context).unfocus();

                                      bool success = await controller.updatePassword(
                                          _currentPassCtrl.text.trim(),
                                          _newPassCtrl.text.trim(),
                                          _confirmPassCtrl.text.trim()
                                      );

                                      if (success) {
                                        // Clear form on success
                                        _currentPassCtrl.clear();
                                        _newPassCtrl.clear();
                                        _confirmPassCtrl.clear();
                                      }
                                    }
                                  },
                                  child: controller.isLoading.value
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("UPDATE PASSWORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}