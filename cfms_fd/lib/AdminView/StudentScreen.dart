import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../ViewModel/Controller/AdminController/StudentController.dart';

class StudentScreen extends StatefulWidget {
  final String token;
  const StudentScreen({super.key, required this.token, required String email});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final StudentController controller = Get.put(StudentController());

  @override
  void initState() {
    super.initState();
    controller.initializeData(widget.token);
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
            child: RefreshIndicator(
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              onRefresh: () async {
                controller.clearFilters();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= PANEL 1: GLASSMORPHIC EXCEL BULK IMPORT =================
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
                                Obx(() => Row(
                                  children: [
                                    const Text(
                                      "File Path:",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                                        child: Text(
                                          controller.selectedFilePath.value.isEmpty ? "No file selected" : controller.selectedFilePath.value.split('/').last,
                                          style: TextStyle(
                                            color: controller.selectedFilePath.value.isEmpty ? Colors.white60 : Colors.white,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3F51B5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: () => controller.browseFile(),
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
                                        onPressed: controller.isUploading.value ? null : () => controller.importExcel(),
                                        icon: controller.isUploading.value
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                            : const Icon(Icons.file_upload, color: Colors.white, size: 20),
                                        label: Text(
                                          controller.isUploading.value ? "Importing..." : "Import",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ================= PANEL 2: GLASSMORPHIC GRID FILTERS =================
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Department Dropdown
                                    Expanded(
                                      child: Obx(() => DropdownButtonFormField<String>(
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        value: (controller.departments.contains(controller.selectedDepartment.value) && controller.selectedDepartment.value.isNotEmpty) ? controller.selectedDepartment.value : null,
                                        hint: const Text("Select Department", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Department",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: controller.departments.map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                                        }).toList(),
                                        onChanged: (val) => controller.onDepartmentChanged(val),
                                      )),
                                    ),
                                    const SizedBox(width: 10),
                                    // Program Dropdown
                                    Expanded(
                                      child: Obx(() => DropdownButtonFormField<String>(
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        value: (controller.programs.contains(controller.selectedProgram.value) && controller.selectedProgram.value.isNotEmpty) ? controller.selectedProgram.value : null,
                                        hint: const Text("Select Program", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Program",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: controller.programs.map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                                        }).toList(),
                                        onChanged: (val) => controller.onProgramChanged(val),
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Batch Dropdown
                                    Expanded(
                                      child: Obx(() => DropdownButtonFormField<String>(
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        value: (controller.batches.contains(controller.selectedBatch.value) && controller.selectedBatch.value.isNotEmpty) ? controller.selectedBatch.value : null,
                                        hint: const Text("Select Batch", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Batch",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: controller.batches.map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                                        }).toList(),
                                        onChanged: (val) => controller.onBatchChanged(val),
                                      )),
                                    ),
                                    const SizedBox(width: 10),
                                    // Section Dropdown
                                    Expanded(
                                      child: Obx(() => DropdownButtonFormField<String>(
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        value: controller.selectedSection.value.isEmpty ? null : controller.selectedSection.value,
                                        hint: const Text("Select Section", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Section",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: controller.sections.map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                                        }).toList(),
                                        onChanged: (val) => controller.onSectionChanged(val),
                                      )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ================= HORIZONTALLY SCROLLABLE TABLE AREA =================
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 780,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E).withOpacity(0.9),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text("Reg No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                    Expanded(flex: 3, child: Text("Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                    Expanded(flex: 2, child: Text("Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                    Expanded(flex: 2, child: Text("Batch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                    Expanded(flex: 1, child: Text("Sec", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                    SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),

                              Container(
                                height: 380,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                ),
                                child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                                  }

                                  if (controller.filteredStudents.isEmpty) {
                                    return const Center(
                                      child: Text("No students record match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: controller.filteredStudents.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                    itemBuilder: (context, i) {
                                      final student = controller.filteredStudents[i];

                                      // ✨ FIX: Yahan ab lambi logic hata kar seedha Controller wala naya variable use kar liya hai
                                      String sectionName = student['section_display']?.toString() ?? 'N/A';

                                      // 🛠️ FIX: Grid mein data keys ko handle karne ke liye safety fallback lagaya
                                      String displayProgram = student['program']?['program_name'] ?? student['program']?['name'] ?? 'N/A';
                                      String displayBatch = student['batch']?['batch_name'] ?? student['batch']?['name'] ?? 'N/A';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text(student['reg_no']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                            Expanded(flex: 3, child: Text(student['std_name']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                            Expanded(flex: 2, child: Text(displayProgram, style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                            Expanded(flex: 2, child: Text(displayBatch, style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                            Expanded(flex: 1, child: Text(sectionName, style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center)),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                            SizedBox(
                                              width: 90,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                    onPressed: () => _editStudentDialog(student),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                    onPressed: () => _confirmDeleteDialog(context, student['id'] is int ? student['id'] : int.parse(student['id'].toString()), student['std_name']?.toString() ?? ''),
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

  // ================= 8. WORKING EDIT STUDENT DIALOG (MAPPED TO BACKEND UPDATE) =================
  void _editStudentDialog(dynamic student) {
    final nameController = TextEditingController(text: student['std_name']?.toString() ?? '');
    final regController = TextEditingController(text: student['reg_no']?.toString() ?? '');

    // 🛠️ FIX: Dialog load hote waqt donon tarah ki keys ka validation kiya
    String originalProg = (student['program']?['program_name'] ?? student['program']?['name'] ?? '').toString().trim();
    String originalBatch = (student['batch']?['batch_name'] ?? student['batch']?['name'] ?? '').toString().trim();

    List<String> allUniquePrograms = controller.masterPrograms
        .map((e) => (e['program_name'] ?? e['name'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    List<String> allUniqueBatches = controller.masterBatches
        .map((e) => (e['batch_name'] ?? e['name'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    String? selectedProg = allUniquePrograms.contains(originalProg) ? originalProg : (allUniquePrograms.isNotEmpty ? allUniquePrograms.first : null);
    String? selectedBatch = allUniqueBatches.contains(originalBatch) ? originalBatch : (allUniqueBatches.isNotEmpty ? allUniqueBatches.first : null);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Student Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Student Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: regController,
                      decoration: InputDecoration(
                        labelText: "Registration Number",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedProg,
                      decoration: InputDecoration(
                        labelText: "Program",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: allUniquePrograms.map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedProg = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedBatch,
                      decoration: InputDecoration(
                        labelText: "Batch",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: allUniqueBatches.map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedBatch = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || regController.text.trim().isEmpty || selectedProg == null || selectedBatch == null) {
                      controller.showSnackBar("Warning", "All structural data fields are required.", isError: true);
                      return;
                    }

                    Navigator.pop(ctx); // Close Dialog
                    controller.isLoading.value = true;

                    try {
                      final url = Uri.parse("${controller.baseUrl}/students/${student['id']}");
                      final Map<String, String> putHeaders = {
                        'Accept': 'application/json',
                        if (controller.authToken.isNotEmpty) 'Authorization': 'Bearer ${controller.authToken}',
                        'Content-Type': 'application/json',
                      };

                      final bodyData = jsonEncode({
                        'std_name': nameController.text.trim(),
                        'reg_no': regController.text.trim(),
                        'program_name': selectedProg,
                        'batch_name': selectedBatch,
                      });

                      final response = await http.put(url, headers: putHeaders, body: bodyData);
                      final responseData = jsonDecode(response.body);

                      if (response.statusCode == 200) {
                        controller.showSnackBar("Success", responseData['message'] ?? "Student details updated successfully.");
                        controller.fetchStudents(); // Table refresh live reload
                      } else if (response.statusCode == 422) {
                        String errorMsg = responseData['message'] ?? "Validation failure on backend pipelines.";

                        if (responseData['errors'] != null) {
                          var validationErrors = responseData['errors'];
                          if (validationErrors is Map) {
                            validationErrors.forEach((key, value) {
                              if (value is List) {
                                errorMsg += "\n• ${value.join(', ')}";
                              } else {
                                errorMsg += "\n• $value";
                              }
                            });
                          } else if (validationErrors is List) {
                            errorMsg += "\n" + validationErrors.join("\n");
                          }
                        }
                        controller.showSnackBar("Validation Error (422)", errorMsg, isError: true);
                      } else {
                        controller.showSnackBar("Server Error", responseData['message'] ?? "Failed to save data record.", isError: true);
                      }
                    } catch (e) {
                      controller.showSnackBar("Pipeline Exception", "Transmission failed: $e", isError: true);
                    } finally {
                      controller.isLoading.value = false;
                    }
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= 9. DELETE CONFIRMATION DIALOG =================
  void _confirmDeleteDialog(BuildContext context, int studentId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Action", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to permanently delete $name from the system?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.deleteStudent(studentId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}