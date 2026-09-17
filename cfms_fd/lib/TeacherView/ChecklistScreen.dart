import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/TeacherController/ChecklistController.dart';

class ChecklistScreen extends StatefulWidget {
  final String token;
  const ChecklistScreen({super.key, required this.token});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late ChecklistController controller;
  String? _selectedAllocId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChecklistController(token: widget.token));
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await controller.fetchAllocations();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _selectedAllocId = null;
    });
    controller.checklist.clear();
    await _loadInitialData();
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onRefresh: _handleRefresh,
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // --- TOP HEADER ---


                  // --- GLASSMORPHISM SELECTION PANEL ---
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
                            const Text("Select a course to view its submission checklist:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 16),
                            Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedAllocId,
                              dropdownColor: const Color(0xFF1E3C72),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Allocated Course", Icons.library_books),
                              hint: const Text("Select Course", style: TextStyle(color: Colors.white70)),
                              items: controller.allocations.map((a) {
                                String courseName = a['course_offered']?['course']?['course_name'] ?? 'Unknown Course';
                                String courseCode = a['course_offered']?['course']?['course_code'] ?? 'N/A';
                                String sessionName = a['session']?['s_name'] ?? 'Unknown Session';
                                String section = a['section'] ?? 'N/A';

                                return DropdownMenuItem(
                                  value: a['id'].toString(),
                                  child: Text("$courseName ($courseCode) - $sessionName [$section]", style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedAllocId = val;
                                  controller.checklist.clear();
                                });

                                if (val != null) {
                                  controller.fetchChecklist(val);
                                }
                              },
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- DATA GRID ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 4, child: Text("File Requirement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text("Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                    ),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))));
                      }
                      if (_selectedAllocId == null) {
                        return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Select a course to view checklist status.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                      }
                      if (controller.checklist.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No file requirements configured.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.checklist.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (_, i) {
                          var item = controller.checklist[i];
                          bool isComplete = item['status'] == 'Complete';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                    flex: 4,
                                    child: Text(item['file_name'] ?? 'Unknown File', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)))
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        item['status'] ?? 'Incomplete',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isComplete ? Colors.green : Colors.redAccent
                                        )
                                    )
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: isComplete
                                        ? IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.visibility, color: Color(0xFF3F51B5), size: 24),
                                      onPressed: () => controller.viewFile(item['file_path'] ?? ''),
                                    )
                                        : const SizedBox(height: 24), // Empty space if incomplete
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
            ),
          ),
        ],
      ),
    );
  }
}