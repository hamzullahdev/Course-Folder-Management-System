import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/TeacherController/ViewClosController.dart';

class ViewClosScreen extends StatefulWidget {
  final String token;
  const ViewClosScreen({super.key, required this.token});

  @override
  State<ViewClosScreen> createState() => _ViewClosScreenState();
}

class _ViewClosScreenState extends State<ViewClosScreen> {
  late ViewClosController controller;
  String? _selectedAllocId;
  String? _extractedCourseId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ViewClosController(token: widget.token));
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await controller.fetchAllocations();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _selectedAllocId = null;
      _extractedCourseId = null;
    });
    controller.closList.clear();
    await _loadInitialData();
  }

  // Safe extraction logic to find the actual Course ID from allocation data
  String? _extractCourseIdSafely(dynamic alloc) {
    if (alloc == null) return null;
    try {
      if (alloc['course_offered'] != null && alloc['course_offered']['course'] != null) {
        return alloc['course_offered']['course']['id'].toString();
      }
      if (alloc['courseOffered'] != null && alloc['courseOffered']['course'] != null) {
        return alloc['courseOffered']['course']['id'].toString();
      }
      if (alloc['course'] != null && alloc['course']['id'] != null) {
        return alloc['course']['id'].toString();
      }
      if (alloc['course_id'] != null) {
        return alloc['course_id'].toString();
      }
    } catch (e) {
      debugPrint("Extraction error: $e");
    }
    return null;
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
              onRefresh: _handleRefresh,
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
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
                            const Text("Select a course to view its mapped CLOs:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 16),
                            Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedAllocId,
                              dropdownColor: const Color(0xFF1E3C72),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Allocated Course", Icons.menu_book),
                              hint: const Text("Select Course", style: TextStyle(color: Colors.white70)),
                              items: controller.allocations.map((a) {
                                String courseName = a['course_offered']?['course']?['course_name'] ?? 'Unknown Course';
                                String courseCode = a['course_offered']?['course']?['course_code'] ?? 'Unknown Code';
                                return DropdownMenuItem(
                                  value: a['id'].toString(),
                                  child: Text("$courseName ($courseCode)", style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedAllocId = val;
                                  controller.closList.clear();

                                  var alloc = controller.allocations.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                  _extractedCourseId = _extractCourseIdSafely(alloc);
                                });

                                if (_extractedCourseId != null) {
                                  controller.fetchClosByCourse(_extractedCourseId!);
                                } else {
                                  Get.snackbar("Error", "Could not extract Course ID.", backgroundColor: Colors.redAccent, colorText: Colors.white);
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
                        Expanded(flex: 2, child: Text("CLO Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 4, child: Text("Description", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                        return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Select a course to view CLOs.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                      }
                      if (controller.closList.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No CLOs found for this course.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                      }

                      // ✨ FIX: Smart numeric ascending sort logic for CLO codes
                      List<dynamic> sortedClos = List<dynamic>.from(controller.closList);
                      sortedClos.sort((a, b) {
                        String codeA = a['clos_code']?.toString() ?? '';
                        String codeB = b['clos_code']?.toString() ?? '';

                        int numA = int.tryParse(codeA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        int numB = int.tryParse(codeB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                        return numA.compareTo(numB);
                      });

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedClos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (_, i) {
                          var clo = sortedClos[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: Text(clo['clos_code'] ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)))),
                                Expanded(flex: 4, child: Text(clo['clos_description'] ?? 'No description.', style: const TextStyle(fontSize: 13, color: Colors.black87))),
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