import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/AdminController/CourseOfferedController.dart'; // Adjust path as needed

class CourseOfferedScreen extends StatefulWidget {
  final String? token;
  const CourseOfferedScreen({super.key, this.token});

  @override
  State<CourseOfferedScreen> createState() => _CourseOfferedScreenState();
}

class _CourseOfferedScreenState extends State<CourseOfferedScreen> {
  final CourseOfferedController _controller = Get.put(CourseOfferedController());

  @override
  void initState() {
    super.initState();
    _controller.initializeData(widget.token ?? "");
  }

  Future<void> _onRefresh() async {
    // Sirf controller ki values clear karein, Obx khud UI reset kar dega
    _controller.selectedDepartment.value = '';
    _controller.selectedProgram.value = '';
    _controller.selectedSession.value = '';
    _controller.selectedFilePath.value = '';

    // Fetch fresh data
    await _controller.fetchDropdownFilters();
    await _controller.fetchOfferedCourses();
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
                                          _controller.selectedFilePath.value.isEmpty
                                              ? "No file selected"
                                              : _controller.selectedFilePath.value.split('/').last,
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
                                        label: Text(_controller.isUploading.value ? "Processing..." : "Import", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 3. Dropdown Filters
                                _buildGlassDropdown("Department", "dept_name", _controller.departmentsList, 'dept'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Yahan programsList ki jagah filteredProgramsList use kiya hai dependent logic ke liye
                                    Expanded(child: _buildGlassDropdown("Program", "program_name", _controller.filteredProgramsList, 'prog')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGlassDropdown("Session", "s_name", _controller.sessionsList, 'sess')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ================= ROW WISE SCROLLABLE DATA GRID =================
                      LayoutBuilder(
                          builder: (context, constraints) {
                            final double computedWidth = max(constraints.maxWidth, 750);

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
                                          Expanded(flex: 3, child: Text("Course Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          Expanded(flex: 2, child: Text("Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          Expanded(flex: 2, child: Text("Short Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          Expanded(flex: 1, child: Text("Cr. Hrs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                          SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                                          SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
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
                                      child: Obx(() {
                                        if (_controller.isLoading.value) {
                                          return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                                        }

                                        if (_controller.filteredOfferedCourses.isEmpty) {
                                          return const Center(child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)));
                                        }

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: _controller.filteredOfferedCourses.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                          itemBuilder: (_, i) {
                                            var item = _controller.filteredOfferedCourses[i];
                                            var course = item['course'] ?? {};

                                            return Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(flex: 3, child: Text(course['course_name'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                  const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                  Expanded(flex: 2, child: Text(course['course_code'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                  Expanded(flex: 2, child: Text(course['short_name'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                                  Expanded(flex: 1, child: Text(course['credit_hrs']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black54, fontSize: 13), textAlign: TextAlign.center)),
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
                                                          onPressed: () {
                                                            Get.snackbar("Notice", "Edit form integration required.");
                                                          },
                                                        ),
                                                        IconButton(
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                          onPressed: () => _controller.deleteCourse(item['id']),
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

  // ================= GLASSMORPHIC DROPDOWN BUILDER =================
  // GlobalKeys remove kar diye gaye hain. Obx khud state manage karega.
  Widget _buildGlassDropdown(String label, String mapKey, RxList<Map<String, dynamic>> dataList, String filterType) {
    return Obx(() {
      String currentValue = '';
      if (filterType == 'dept') currentValue = _controller.selectedDepartment.value;
      if (filterType == 'prog') currentValue = _controller.selectedProgram.value;
      if (filterType == 'sess') currentValue = _controller.selectedSession.value;

      // Safety Guard: Flutter crash karta hai agar selected value Dropdown items mein mojood na ho.
      // Agar currentValue list mein nahi hai (e.g. naya department select hone par program clear karna ho)
      bool isValidValue = dataList.any((item) => (item[mapKey] ?? '') == currentValue);
      if (!isValidValue && currentValue.isNotEmpty) {
        currentValue = ''; // Fallback to "All" option
      }

      return DropdownButtonFormField<String>(
        isDense: true,
        isExpanded: true,
        dropdownColor: const Color(0xFF2A5298),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        value: currentValue, // Ab ye humesha map karega accurately
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
          ...dataList.map((item) {
            String name = item[mapKey] ?? '';
            return DropdownMenuItem<String>(value: name, child: Text(name, overflow: TextOverflow.ellipsis));
          }).toList(),
        ],
        onChanged: (val) {
          if (val != null) {
            _controller.onFilterChanged(filterType, val);
          }
        },
      );
    });
  }
}