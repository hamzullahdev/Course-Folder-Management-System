import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ViewModel/Controller/AdminController/TeacherController.dart';

class TeacherScreen extends StatefulWidget {
  final String? token;
  const TeacherScreen({super.key, this.token});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final TeacherController _controller = Get.put(TeacherController());
  final GlobalKey<FormFieldState> _deptDropdownKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _controller.initializeData(widget.token ?? "");
  }

  Future<void> _handleRefresh() async {
    _controller.selectedDepartment.value = '';
    _controller.selectedFilePath.value = ''; // Cleaned file path on pull-to-refresh
    _deptDropdownKey.currentState?.reset();
    await _controller.fetchDropdownFilters();
    await _controller.fetchTeachers();
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
            child: RefreshIndicator(
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              onRefresh: _handleRefresh,
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
                                // 1. File Path Row
                                Row(
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
                                        child: Obx(() => Text(
                                          _controller.selectedFilePath.value.isEmpty ? "No file selected" : _controller.selectedFilePath.value.split('/').last,
                                          style: TextStyle(
                                            color: _controller.selectedFilePath.value.isEmpty ? Colors.white60 : Colors.white,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // 2. Browse and Import Buttons Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3F51B5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: () => _controller.browseFile(),
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
                                        onPressed: _controller.isUploading.value ? null : () => _controller.importExcel(),
                                        icon: _controller.isUploading.value
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.file_upload, color: Colors.white, size: 20),
                                        label: Text(_controller.isUploading.value ? "Importing..." : "Import", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 3. Dropdown Selection
                                Obx(() => DropdownButtonFormField<String>(
                                  key: _deptDropdownKey,
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF2A5298),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  value: _controller.selectedDepartment.value.isEmpty ? null : _controller.selectedDepartment.value,
                                  hint: const Text("Select Department", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  decoration: InputDecoration(
                                    labelText: "Department",
                                    labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(value: "", child: Text("All Departments")),
                                    ..._controller.departments.map((String d) {
                                      return DropdownMenuItem<String>(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                                    }).toList()
                                  ],
                                  onChanged: (val) => _controller.onDepartmentChanged(val),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ================= ROW WISE SCROLLABLE DATA GRID =================
                      LayoutBuilder(
                          builder: (context, constraints) {
                            final double computedWidth = max(constraints.maxWidth, 720);

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: computedWidth,
                                child: Column(
                                  children: [
                                    // Grid Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withOpacity(0.9),
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(flex: 3, child: Text("Teacher Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          Expanded(flex: 3, child: Text("Email", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          Expanded(flex: 1, child: Text("Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                        ],
                                      ),
                                    ),

                                    // Grid Body
                                    Container(
                                      height: 380,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                      ),
                                      child: Obx(() => _controller.isLoading.value
                                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                                          : _controller.filteredTeachers.isEmpty
                                          ? const Center(child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)))
                                          : ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _controller.filteredTeachers.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                        itemBuilder: (_, i) {
                                          var teacher = _controller.filteredTeachers[i];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 3, child: Text(teacher['teacher_name'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                Expanded(flex: 3, child: Text(teacher['user']?['email'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                const Expanded(flex: 1, child: Text("••••••••", style: TextStyle(color: Colors.black54, fontSize: 13), textAlign: TextAlign.center)),
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
                                                        onPressed: () => _editTeacherDialog(teacher),
                                                      ),
                                                      IconButton(
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                        onPressed: () => _controller.deleteTeacher(teacher['id']),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      )),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }
                      )
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

  // ================= EDIT ALERT DIALOG =================
  void _editTeacherDialog(Map<String, dynamic> teacher) {
    TextEditingController editNameController = TextEditingController(text: teacher['teacher_name']);
    TextEditingController editEmailController = TextEditingController(text: teacher['user']?['email']);
    TextEditingController editPassController = TextEditingController();

    String? currentDept = teacher['department']?['dept_name'] ?? teacher['department']?['name'];
    String? selectedEditDept = _controller.departments.contains(currentDept) ? currentDept : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Modify Teacher Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedEditDept,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                  items: _controller.departments.map((String d) {
                    return DropdownMenuItem<String>(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedEditDept = val),
                ),
                const SizedBox(height: 15),
                TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Teacher Name", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: editEmailController, decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: editPassController, obscureText: true, decoration: const InputDecoration(labelText: "New Password (Optional)", border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              onPressed: () {
                Navigator.pop(context);
                _controller.updateTeacher(
                    teacher['id'],
                    editNameController.text.trim(),
                    editEmailController.text.trim(),
                    editPassController.text.trim(),
                    selectedEditDept ?? ''
                );
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}