import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ViewModel/Controller/TeacherController/MyCoursesController.dart';
import 'FileSubmissionScreen.dart';

class MyCoursesScreen extends StatefulWidget {
  final String token;
  const MyCoursesScreen({super.key, required this.token});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late MyCoursesController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MyCoursesController>()) {
      Get.delete<MyCoursesController>();
    }
    controller = Get.put(MyCoursesController(token: widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
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
            child: Obx(() {
              if (controller.sessions.isEmpty && controller.isLoading.value && controller.allocations.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              return RefreshIndicator(
                onRefresh: controller.fetchMyCourses,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
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
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2A5298),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.white70),
                            decoration: InputDecoration(
                              labelText: "Filter by Session",
                              labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              prefixIcon: const Icon(Icons.date_range, color: Colors.white70),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                            ),
                            value: controller.selectedSessionId.value.isEmpty ? null : controller.selectedSessionId.value,
                            hint: const Text("Select Session", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            items: controller.sessions.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id'].toString(),
                                child: Text(s['s_name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedSessionId.value = val;
                                controller.applyFilter();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.9),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.library_books, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text("Allocated Courses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      ),
                      child: controller.isLoading.value && controller.allocations.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator(color: Color(0xFF1E3C72))))
                          : controller.filteredAllocations.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text("No courses allocated for this session.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500))))
                          : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: controller.filteredAllocations.length,
                        separatorBuilder: (_, __) => const Divider(height: 20, color: Colors.black12, thickness: 1),
                        itemBuilder: (context, index) {
                          var alloc = controller.filteredAllocations[index];

                          String courseName = 'Unknown Course';
                          String courseCode = 'N/A';
                          String section    = 'N/A';
                          String programName = 'N/A';
                          String batchName  = '';
                          String sessionName = '';

                          try {
                            if (alloc is Map) {
                              section = (alloc['section'] ?? 'N/A').toString();
                              if (alloc['batch'] is Map) batchName = (alloc['batch']['batch_name'] ?? '').toString();
                              if (alloc['session'] is Map) sessionName = (alloc['session']['s_name'] ?? '').toString();

                              var courseObj = alloc['course'] ?? (alloc['course_offered'] is Map ? alloc['course_offered']['course'] : null) ?? (alloc['courseOffered'] is Map ? alloc['courseOffered']['course'] : null);

                              if (courseObj is Map) {
                                courseName = (courseObj['course_name'] ?? courseObj['courseName'] ?? courseObj['name'] ?? 'Unknown Course').toString();
                                courseCode = (courseObj['course_code'] ?? courseObj['courseCode'] ?? courseObj['code'] ?? 'N/A').toString();
                                var program = courseObj['program'];
                                if (program is Map) programName = (program['program_name'] ?? program['programName'] ?? 'N/A').toString();
                              }

                              if (courseCode == 'N/A' || courseCode.isEmpty) {
                                var cOffered = alloc['course_offered'] ?? alloc['courseOffered'];
                                if (cOffered is Map) courseCode = (cOffered['course_code'] ?? cOffered['courseCode'] ?? 'N/A').toString();
                              }
                              if ((courseCode == 'N/A' || courseCode.isEmpty) && alloc['course_code'] != null) {
                                courseCode = alloc['course_code'].toString();
                              }
                            }
                          } catch (e) {
                            debugPrint("Parsing error handled securely: $e");
                          }

                          String semester = controller.calculateSemester(batchName, sessionName);
                          int totalFiles = controller.getTotalRequiredFiles(courseName);
                          int uploadedFiles = controller.getUploadedFilesCount(alloc['id']);

                          double progressValue = (totalFiles > 0 ? (uploadedFiles / totalFiles) : 0.0).clamp(0.0, 1.0);
                          int progressPercentage = (progressValue * 100).toInt();

                          bool isSubmitted = controller.isFolderSubmitted(alloc['id']);
                          bool isAccepted = controller.isFolderAccepted(alloc['id']);
                          bool isRejected = controller.isFolderRejected(alloc['id']);

                          // ✨ CHECK: Disable Submit visually if rejected and not managed yet
                          bool disableSubmit = isRejected && !controller.canResubmit(alloc['id']);
                          Color submitBtnColor = disableSubmit ? Colors.grey : Colors.green;

                          return Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isSubmitted || isAccepted) ? Colors.grey[200] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(10)),
                                          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3C72), size: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(courseName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                              const SizedBox(height: 4),
                                              Text(courseCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3F51B5))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24, color: Colors.black12),

                                    Row(
                                      children: [
                                        Expanded(child: _buildInfoRow("Semester", semester)),
                                        Expanded(child: _buildInfoRow("Section", section)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildInfoRow("Program", programName)),
                                        Expanded(child: _buildInfoRow("Batch", batchName)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("UPLOAD PROGRESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        Text("$progressPercentage% ($uploadedFiles/$totalFiles)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progressValue,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(progressPercentage == 100 ? Colors.green : const Color(0xFF1E3C72)),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    (isSubmitted || isAccepted)
                                        ? Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(color: isAccepted ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(8)),
                                            child: Center(
                                              child: Text(isAccepted ? "ACCEPTED" : "SUBMITTED", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          height: 46,
                                          width: 46,
                                          decoration: BoxDecoration(color: isAccepted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: isAccepted ? Colors.green : Colors.transparent)),
                                          child: IconButton(
                                            icon: Icon(Icons.download_for_offline, color: isAccepted ? Colors.green : const Color(0xFF1E3C72)),
                                            onPressed: () {
                                              controller.downloadZip(alloc['id']);
                                              Get.snackbar("Downloading", "Bundle is preparing to download...", backgroundColor: Colors.green, colorText: Colors.white);
                                            },
                                          ),
                                        )
                                      ],
                                    )
                                        : Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: 46,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF3F51B5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 2,
                                            ),
                                            onPressed: () async {
                                              // Navigate to Manage Files screen
                                              await Get.to(() => FileSubmissionScreen(
                                                token: widget.token,
                                                allocationId: alloc['id'].toString(),
                                                courseName: courseName,
                                                courseCode: courseCode,
                                                sessionName: sessionName,
                                                batchName: batchName,
                                                section: section,
                                                semester: semester,
                                              ));

                                              // ✨ LOCK OPEN: Wapis aane par Submit ka button open kar do
                                              if (isRejected) {
                                                controller.unlockResubmit(alloc['id']);
                                              }
                                              controller.fetchMyCourses();
                                            },
                                            child: const Text("MANAGE FILES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                          ),
                                        ),
                                        if (progressPercentage == 100) ...[
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 46,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: submitBtnColor, // ✨ Color based on lock state
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 2,
                                              ),
                                              onPressed: () {
                                                // ✨ CHECK LOCK STATE
                                                if (disableSubmit) {
                                                  Get.snackbar(
                                                      "Action Required",
                                                      "Please click 'MANAGE FILES' and update the requested documents before resubmitting.",
                                                      backgroundColor: Colors.orange,
                                                      colorText: Colors.white,
                                                      duration: const Duration(seconds: 4)
                                                  );
                                                  return;
                                                }
                                                controller.submitFolder(alloc['id']);
                                              },
                                              child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),

                                    if (isRejected) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                            "Reason: ${controller.getRejectionReason(alloc['id'])}",
                                            style: const TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic)
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),

                              if (isSubmitted)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "PENDING",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}