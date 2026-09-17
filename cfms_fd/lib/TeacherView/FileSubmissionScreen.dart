import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // ✨ Package Import Kiya Hai
import '../ViewModel/Controller/TeacherController/FileSubmissionController.dart';

class FileSubmissionScreen extends StatefulWidget {
  final String token;
  final String allocationId;
  final String courseName;
  final String courseCode;
  final String sessionName;
  final String batchName;
  final String section;
  final String semester;

  const FileSubmissionScreen({
    super.key,
    required this.token,
    required this.allocationId,
    required this.courseName,
    required this.courseCode,
    required this.sessionName,
    required this.batchName,
    required this.section,
    required this.semester,
  });

  @override
  State<FileSubmissionScreen> createState() => _FileSubmissionScreenState();
}

class _FileSubmissionScreenState extends State<FileSubmissionScreen> {
  late FileSubmissionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FileSubmissionController(token: widget.token, allocationId: widget.allocationId));
  }

  // ✨ File Open aur Download karne ka function (Fully Fixed)
  Future<void> _launchURL(String filePath) async {
    // 1. Controller ke baseUrl se '/api' hata kar asal domain nikal lein (is se automatically working IP aa jayega)
    String domain = controller.baseUrl.replaceAll('/api', '');

    // 2. Windows ke backslashes (\) ko forward slashes (/) mein badlein
    String cleanPath = filePath.replaceAll('\\', '/');

    // 3. Mukammal URL banayein
    String fileUrl = "$domain/storage/$cleanPath";

    // 4. Spaces ko theek karne ke liye Encode karein
    String encodedUrl = Uri.encodeFull(fileUrl);
    final Uri url = Uri.parse(encodedUrl);

    print("Opening exact URL: $url"); // Console mein final URL check karne ke liye

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Error", "Could not open the browser.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      print("URL Error: $e");
      Get.snackbar("Error", "Could not open the browser", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ================= BACKGROUND GRADIENT =================
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === TOP HEADER ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Get.back(),
                      ),
                      const Text("FILE SUBMISSION", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                ),

                // === MAIN CONTENT BODY ===
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF1E3C72),
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      await controller.fetchFolders();
                      await controller.fetchSubmissions();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. COURSE INFO CARD (GLASSMORPHISM)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.menu_book, color: Colors.white, size: 24),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "${widget.courseName} (${widget.courseCode})",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: Colors.white30, height: 1),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoText("Semester", widget.semester),
                                        _buildInfoText("Session", widget.sessionName),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoText("Batch", widget.batchName),
                                        _buildInfoText("Section", widget.section),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. UPLOAD FORM CARD (GLASSMORPHISM)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Upload Document", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Obx(() => Column(
                                      children: [
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFF2A5298),
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                          decoration: _glassInputDeco("Select Folder", Icons.folder_open),
                                          value: controller.selectedFolderId.value.isEmpty ? null : controller.selectedFolderId.value,
                                          items: controller.folders.map<DropdownMenuItem<String>>((dynamic f) {
                                            String fId = f['folder_id']?.toString() ?? f['id']?.toString() ?? '';
                                            String fName = f['folder_name']?.toString() ?? f['name']?.toString() ?? 'Unknown';
                                            return DropdownMenuItem<String>(
                                              value: fId.isEmpty ? null : fId,
                                              child: Text(fName, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              controller.selectedFolderId.value = val;
                                              controller.fetchFilesByFolder(val);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFF2A5298),
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                          decoration: _glassInputDeco("Select File Type", Icons.insert_drive_file),
                                          value: controller.selectedFileId.value.isEmpty ? null : controller.selectedFileId.value,
                                          items: controller.files.map<DropdownMenuItem<String>>((dynamic f) {
                                            String fId = f['file_id']?.toString() ?? f['id']?.toString() ?? '';
                                            String fName = f['file_name']?.toString() ?? f['name']?.toString() ?? 'Unknown';
                                            return DropdownMenuItem<String>(
                                              value: fId.isEmpty ? null : fId,
                                              child: Text(fName, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              controller.selectedFileId.value = val;
                                              controller.updateFileNameDisplay();
                                            }
                                          },
                                        ),
                                      ],
                                    )),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Obx(() => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white30),
                                            ),
                                            child: Text(
                                              controller.selectedFileName.value.isEmpty ? "No document selected..." : controller.selectedFileName.value,
                                              style: TextStyle(color: controller.selectedFileName.value.isEmpty ? Colors.white54 : Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          onPressed: controller.pickFile,
                                          child: const Text("BROWSE", style: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    Obx(() => SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3F51B5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 5,
                                        ),
                                        onPressed: controller.isUploading.value ? null : controller.uploadDocument,
                                        child: controller.isUploading.value
                                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text("UPLOAD FILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 3. UPLOAD FILE LIST GRID
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 10),
                            child: Text("Uploaded Documents", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              children: [
                                // List Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A237E).withOpacity(0.9),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 3, child: Text("FILE PATH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                      Expanded(flex: 1, child: Text("ACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                    ],
                                  ),
                                ),
                                // List Body
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                  ),
                                  child: Obx(() {
                                    if (controller.isLoading.value) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3C72))));
                                    if (controller.uploadedSubmissions.isEmpty) return const Padding(padding: EdgeInsets.all(30), child: Center(child: Text("No files uploaded yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: controller.uploadedSubmissions.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                                      itemBuilder: (context, index) {
                                        var sub = controller.uploadedSubmissions[index];

                                        // ✨ DYNAMIC EXTENSION EXTRACTION LOGIC
                                        String displayPath = sub['file_name']?.toString() ?? 'Unknown File';
                                        String filePath = sub['file_path']?.toString() ?? '';

                                        if (filePath.contains('.')) {
                                          String extension = '.${filePath.split('.').last}';
                                          // Append extension only if it is not already present in the display name
                                          if (!displayPath.toLowerCase().endsWith(extension.toLowerCase())) {
                                            displayPath = '$displayPath$extension';
                                          }
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  displayPath,
                                                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      icon: const Icon(Icons.remove_red_eye, color: Color(0xFF3F51B5), size: 20),
                                                      onPressed: () {
                                                        String path = sub['file_path'] ?? '';
                                                        if (path.isNotEmpty) {
                                                          _launchURL(path);
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                      onPressed: () {
                                                        String fileId = sub['file_id']?.toString() ?? sub['id']?.toString() ?? '';
                                                        controller.triggerEditMode(fileId);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Info Text in Header Card
  Widget _buildInfoText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Updated Glassmorphism Input Decoration
  InputDecoration _glassInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}