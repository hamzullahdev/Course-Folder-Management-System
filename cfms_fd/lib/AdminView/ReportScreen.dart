import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/AdminController/ReportController.dart';
import 'ReportChecklistScreen.dart';

class ReportScreen extends StatefulWidget {
  final String token;
  const ReportScreen({super.key, required this.token});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReportController(token: widget.token));
  }

  Future<void> _onRefresh() async {
    controller.resetAllFilters();
    await controller.fetchFilters();
    await controller.fetchReports();
  }

  // ✨ FIX: Dropdown building logic optimized to handle pure strings (like section) and objects safely
  Widget _buildGlassDropdown(String label, List<dynamic> sourceList, String valueKey, String labelKey, RxString targetingValue, {Function? onChangeOverride}) {
    return Obx(() {
      return DropdownButtonFormField<String>(
        isDense: true,
        isExpanded: true,
        dropdownColor: const Color(0xFF2A5298),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        // Only set value if it exists in the currently available source list
        value: targetingValue.value.isNotEmpty && sourceList.any((item) {
          String val = item is String ? item : item[valueKey].toString();
          return val == targetingValue.value;
        }) ? targetingValue.value : null,
        hint: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white54)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white30)),
        ),
        items: sourceList.map((dynamic item) {
          String val = item is String ? item : item[valueKey].toString();
          String display = item is String ? "Section $item" : item[labelKey].toString();
          return DropdownMenuItem<String>(value: val, child: Text(display, overflow: TextOverflow.ellipsis));
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            targetingValue.value = newValue;
            if (onChangeOverride != null) onChangeOverride();
            controller.fetchReports();
          }
        },
      );
    });
  }

  void _showRejectionModal(int allocationId, String courseName) {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Package Rejection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Provide compliance feedback for:", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(courseName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "e.g., File structure audit missing proofs...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if(reasonController.text.trim().isEmpty) {
                Get.snackbar("Required", "Rejection reason is mandatory.", backgroundColor: Colors.orange, colorText: Colors.white);
                return;
              }
              Navigator.pop(context);
              await controller.rejectPackage(allocationId, reasonController.text.trim());
            },
            child: const Text("Log Exception", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: RefreshIndicator(
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.all(12.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Course Audit Reports", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                              Text("Monitor and verify structure compliance.", style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                // ✨ Department clears Program only
                                Expanded(child: _buildGlassDropdown("Department", controller.rawDepartments, 'id', 'dept_name', controller.selectedDept, onChangeOverride: () => controller.selectedProg.value = '')),
                                const SizedBox(width: 8),
                                Expanded(child: Obx(() => _buildGlassDropdown("Program", controller.filteredPrograms, 'id', 'program_name', controller.selectedProg))),
                                const SizedBox(width: 8),
                                // ✨ Session is Independent
                                Expanded(child: _buildGlassDropdown("Session", controller.sessions, 'id', 's_name', controller.selectedSess)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // ✨ Batch, Section, Teacher are completely independent
                                Expanded(child: _buildGlassDropdown("Batch", controller.batches, 'id', 'batch_name', controller.selectedBatch)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildGlassDropdown("Section", controller.sections, '', '', controller.selectedSec)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildGlassDropdown("Teacher", controller.teachers, 'id', 'teacher_name', controller.selectedTeacher)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 10),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildVerticalToggleOption("Complete Package (Approved / Submitted)", Icons.check_circle, Colors.greenAccent, 'complete'),
                                const SizedBox(height: 8),
                                _buildVerticalToggleOption("Incomplete Package (In Progress / Rejected)", Icons.access_time_filled, Colors.orangeAccent, 'incomplete'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 880,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A237E),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 170, child: Text("Course Detail", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                              SizedBox(width: 110, child: Text("Session & Sem", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                              SizedBox(width: 130, child: Text("Prog & Batch", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                              SizedBox(width: 60, child: Text("Section", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 120, child: Text("Teacher", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                              SizedBox(width: 100, child: Text("Status", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 160, child: Text("Actions", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        Container(
                          width: 880,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                          child: Obx(() {
                            if (controller.isDataLoading.value) {
                              return const Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))));
                            }
                            if (controller.reportsList.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(35.0), child: Center(child: Text("No records match your selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500))));
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.reportsList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                              itemBuilder: (_, i) {
                                var row = controller.reportsList[i];
                                String status = (row['status'] ?? 'in progress').toString().toLowerCase();
                                bool isApproved = status == 'approved';
                                bool isRejected = status == 'rejected';

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 170, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(row['course_offered']?['course']?['course_name']?.toString() ?? 'Unknown Subject', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(row['course_offered']?['course']?['course_code']?.toString() ?? 'N/A', style: const TextStyle(color: Color(0xFF3F51B5), fontSize: 10, fontWeight: FontWeight.bold))
                                          ])),
                                          SizedBox(width: 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(row['session']?['s_name']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text("${row['semester_text'] ?? '1st'} Semester", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))
                                          ])),
                                          SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(row['course_offered']?['course']?['program']?['program_name']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(row['batch']?['batch_name']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))
                                          ])),
                                          SizedBox(width: 60, child: Text(row['section']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                          SizedBox(width: 120, child: Text(row['teacher']?['teacher_name']?.toString() ?? 'Not Assigned', style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          SizedBox(width: 100, child: Center(child: _buildStatusBadge(status))),

                                          SizedBox(width: 160, child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.remove_red_eye, color: Colors.blue, size: 20),
                                                tooltip: "View Files",
                                                onPressed: () {
                                                  Get.to(() => ReportChecklistScreen(
                                                    token: widget.token,
                                                    allocationId: row['id'].toString(),
                                                    courseName: row['course_offered']?['course']?['course_name']?.toString() ?? 'Subject',
                                                  ));
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.download_for_offline, color: Color(0xFF1E3C72), size: 20),
                                                tooltip: "Download ZIP",
                                                onPressed: () => controller.downloadZip(row['id']),
                                              ),
                                              const SizedBox(width: 8),

                                              if (controller.completionContext.value == 'complete' || isRejected) ...[
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: Icon(Icons.check_circle, color: isApproved ? Colors.grey : Colors.green, size: 20),
                                                  tooltip: "Accept",
                                                  onPressed: isApproved ? null : () => controller.acceptPackage(row['id']),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: Icon(Icons.cancel, color: isApproved ? Colors.grey : Colors.redAccent, size: 20),
                                                  tooltip: "Reject",
                                                  onPressed: isApproved ? null : () => _showRejectionModal(row['id'], row['course_offered']?['course']?['course_name']?.toString() ?? 'Subject'),
                                                ),
                                              ]
                                            ],
                                          )),
                                        ],
                                      ),
                                    ),
                                    if (isRejected && row['reason'] != null)
                                      Container(
                                        width: double.infinity,
                                        color: Colors.red.withOpacity(0.05),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline, color: Colors.red, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text("Rejection Feedback: ${row['reason']}", style: const TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic))),
                                          ],
                                        ),
                                      )
                                  ],
                                );
                              },
                            );
                          }),
                        ),
                      ],
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

  Widget _buildVerticalToggleOption(String label, IconData icon, Color color, String contextValue) {
    return Obx(() {
      bool isSelected = controller.completionContext.value == contextValue;
      return GestureDetector(
        onTap: () {
          controller.completionContext.value = contextValue;
          controller.fetchReports();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
              border: Border.all(color: isSelected ? Colors.white70 : Colors.white12),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    label,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    )
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    if (status == 'approved') { bg = Colors.green.shade50; text = Colors.green; }
    else if (status == 'submitted') { bg = Colors.orange.shade50; text = Colors.orange; }
    else if (status == 'rejected') { bg = Colors.red.shade50; text = Colors.red; }
    else { bg = Colors.blue.shade50; text = Colors.blue; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: text.withOpacity(0.3))),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}