import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/AdminController/EnrollmentController.dart';

class EnrollmentScreen extends StatefulWidget {
  final String? token;
  const EnrollmentScreen({super.key, this.token});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final EnrollmentController controller = Get.put(EnrollmentController());

  @override
  void initState() {
    super.initState();
    // ✨ FIX 4: Screen load hote hi hum Controller ko token bhej rahe hain
    if (widget.token != null) {
      controller.initializeData(widget.token!);
    }
  }

  Future<void> _onRefresh() async {
    controller.selectedDept.value = '';
    controller.selectedProg.value = '';
    controller.selectedSess.value = '';
    controller.selectedSec.value = '';
    controller.selectedSub.value = '';
    controller.filePathDisplay.value = '';

    await controller.fetchDropdownData();
    await controller.fetchEnrollments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ================= BACKGROUND DEEP BLUE GRADIENT =================
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ================= GLASSMORPHIC CONTROL PANEL =================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Spreadsheet File Path Row Tracker
                                Row(
                                  children: [
                                    const Text(
                                      "File Path:",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white38),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Obx(() => Text(
                                          controller.filePathDisplay.value.isEmpty
                                              ? "No spreadsheet selected"
                                              : controller.filePathDisplay.value.split('/').last,
                                          style: TextStyle(
                                            color: controller.filePathDisplay.value.isEmpty ? Colors.white60 : Colors.white,
                                            fontSize: 13,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // 2. Bulk Handling Interaction Action Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3F51B5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: () => controller.browseExcelFile(),
                                        icon: const Icon(Icons.folder_open, color: Colors.white, size: 20),
                                        label: const Text("Browse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Obx(() => ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: controller.isLoading.value ? null : () => controller.importSpreadsheet(),
                                        icon: controller.isLoading.value
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.file_upload, color: Colors.white, size: 20),
                                        label: Text(controller.isLoading.value ? "Processing..." : "Import", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 3. Glassmorphic Data Filter Rows Matrix
                                _buildGlassDropdown("Department", controller.departments, controller.selectedDept),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildGlassDropdown("Program", controller.programs, controller.selectedProg)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGlassDropdown("Session", controller.sessions, controller.selectedSess)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildGlassDropdown("Section", controller.sections, controller.selectedSec)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGlassDropdown("Subject", controller.subjects, controller.selectedSub)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ================= MULTI-DIRECTIONAL CUSTOM SCROLL DATA GRID =================
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double computedWidth = max(constraints.maxWidth, 920);

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: computedWidth,
                              child: Column(
                                children: [
                                  // Grid Row Header Layout Structure
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A237E).withOpacity(0.9),
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 2, child: Text("Reg No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                        Expanded(flex: 2, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                        Expanded(flex: 1, child: Text("Section", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                        Expanded(flex: 3, child: Text("Subject", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                        Expanded(flex: 2, child: Text("Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                        SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                      ],
                                    ),
                                  ),

                                  // Grid Reactive Body Content Framework
                                  Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                    ),
                                    child: Obx(() {
                                      if (controller.isLoading.value) {
                                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                                      }

                                      if (controller.filteredEnrollments.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            "No records found matching parameters.",
                                            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: controller.filteredEnrollments.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                        itemBuilder: (ctx, i) {
                                          var record = controller.filteredEnrollments[i];

                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 2, child: Text(record['student']?['reg_no']?.toString() ?? '-', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                Expanded(flex: 2, child: Text(record['student']?['std_name']?.toString() ?? '-', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                Expanded(flex: 1, child: Text(record['section']?.toString() ?? '-', style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                Expanded(flex: 3, child: Text(record['course_offered']?['course']?['course_name']?.toString() ?? '-', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                Expanded(flex: 2, child: Text(record['course_offered']?['session']?['s_name']?.toString() ?? '-', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                SizedBox(
                                                  width: 80,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      IconButton(
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                        onPressed: () => _showEditDialog(ctx, record),
                                                      ),
                                                      IconButton(
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                        onPressed: () => controller.deleteEnrollment(record['id']),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= GLASSMORPHIC STATEFUL DROPDOWN BUILDER =================
  Widget _buildGlassDropdown(String label, RxList<String> optionsList, RxString targetingValue) {
    return Obx(() {
      String currentValue = targetingValue.value;

      bool isValidValue = optionsList.contains(currentValue);
      if (!isValidValue && currentValue.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => targetingValue.value = '');
        currentValue = '';
      }

      return DropdownButtonFormField<String>(
        isDense: true,
        isExpanded: true,
        dropdownColor: const Color(0xFF2A5298),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        value: currentValue.isEmpty ? "" : currentValue,
        hint: Text("Select $label", style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
        ),
        items: [
          DropdownMenuItem<String>(value: "", child: Text("All ${label}s")),
          ...optionsList.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ],
        onChanged: (newValue) {
          if (newValue != null) {
            targetingValue.value = newValue;
            controller.applyFilters();
          }
        },
      );
    });
  }

  // ================= MUTATION MANAGEMENT MODAL ENGINE =================
  void _showEditDialog(BuildContext ctx, dynamic record) {
    final TextEditingController sectionController = TextEditingController(text: record['section']?.toString() ?? '');

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: Text(
            "Modify Record: ${record['student']?['reg_no']}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sectionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Section Assignment Name",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Map<String, dynamic> body = {
                  "student_id": record['student_id'],
                  "course_offered_id": record['course_offered_id'],
                  "section": sectionController.text.trim(),
                };
                controller.updateEnrollment(record['id'], body);
                Navigator.pop(context);
              },
              child: const Text("Save Context", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}