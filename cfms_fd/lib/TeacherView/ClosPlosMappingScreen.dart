import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/TeacherController/ClosPlosMappingController.dart';

class ClosPlosMappingScreen extends StatefulWidget {
  final String token;
  const ClosPlosMappingScreen({super.key, required this.token});

  @override
  State<ClosPlosMappingScreen> createState() => _ClosPlosMappingScreenState();
}

class _ClosPlosMappingScreenState extends State<ClosPlosMappingScreen> {
  late ClosPlosMappingController controller;
  String? _selectedAllocId;
  String? _extractedCourseId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ClosPlosMappingController(token: widget.token));
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
    controller.plosList.clear();
    await _loadInitialData();
  }

  String? _extractCourseIdSafely(dynamic alloc) {
    if (alloc == null) return null;
    try {
      if (alloc['course_offered'] != null && alloc['course_offered']['course'] != null) return alloc['course_offered']['course']['id'].toString();
      if (alloc['courseOffered'] != null && alloc['courseOffered']['course'] != null) return alloc['courseOffered']['course']['id'].toString();
      if (alloc['course'] != null && alloc['course']['id'] != null) return alloc['course']['id'].toString();
      if (alloc['course_id'] != null) return alloc['course_id'].toString();
    } catch (e) {
      debugPrint("Extraction error: $e");
    }
    return null;
  }

  void _showInfoDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
        content: Text(description.isEmpty ? 'No description available.' : description, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
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
                  // --- DROPDOWN PANEL ---
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
                            const Text("Select Subject to Map CLOs & PLOs:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 16),
                            Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedAllocId,
                              dropdownColor: const Color(0xFF1E3C72),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Subject", Icons.book_outlined),
                              hint: const Text("Select Subject", style: TextStyle(color: Colors.white70)),
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
                                  var alloc = controller.allocations.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                  _extractedCourseId = _extractCourseIdSafely(alloc);
                                });

                                if (_extractedCourseId != null) {
                                  controller.fetchMappingData(_extractedCourseId!);
                                }
                              },
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- MAPPING MATRIX (DATA TABLE) ---
                  Obx(() {
                    if (controller.isLoading.value && controller.closList.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator(color: Colors.white)));
                    }
                    if (_selectedAllocId == null) {
                      return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Select a subject to view the mapping grid.", style: TextStyle(color: Colors.white70, fontSize: 16))));
                    }
                    if (controller.closList.isEmpty || controller.plosList.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Incomplete data: Either CLOs or PLOs are missing for this course.", style: TextStyle(color: Colors.white70, fontSize: 15))));
                    }

                    // Sort CLOs logically
                    List<dynamic> sortedClos = List<dynamic>.from(controller.closList);
                    sortedClos.sort((a, b) {
                      int numA = int.tryParse(a['clos_code'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      int numB = int.tryParse(b['clos_code'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      return numA.compareTo(numB);
                    });

                    // Sort PLOs logically
                    List<dynamic> sortedPlos = List<dynamic>.from(controller.plosList);
                    sortedPlos.sort((a, b) {
                      int numA = int.tryParse(a['plo_code'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      int numB = int.tryParse(b['plo_code'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      return numA.compareTo(numB);
                    });

                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.grey[300], // Grid line colors
                              ),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                                dataRowHeight: 65,
                                columns: [
                                  const DataColumn(label: Text("CLO / PLO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                  // Generate PLO Columns dynamically
                                  ...sortedPlos.map((plo) => DataColumn(
                                      label: Row(
                                        children: [
                                          Text(plo['plo_code'] ?? 'PLO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                                            onPressed: () => _showInfoDialog(plo['plo_code'], plo['plo_description'] ?? ''),
                                          )
                                        ],
                                      )
                                  )),
                                ],
                                rows: sortedClos.map((clo) {
                                  int cloId = int.parse(clo['id'].toString());
                                  return DataRow(
                                      cells: [
                                        // CLO Row Header Cell
                                        DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(clo['clos_code'] ?? 'CLO', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                                                  onPressed: () => _showInfoDialog(clo['clos_code'], clo['clos_description'] ?? ''),
                                                )
                                              ],
                                            )
                                        ),
                                        // Checkbox Cells for each PLO
                                        ...sortedPlos.map((plo) {
                                          int ploId = int.parse(plo['id'].toString());
                                          return DataCell(
                                              Center(
                                                child: Obx(() {
                                                  bool isChecked = controller.isMapped(cloId, ploId);
                                                  return Transform.scale(
                                                    scale: 1.2, // Make checkbox slightly larger matching design
                                                    child: Checkbox(
                                                      value: isChecked,
                                                      activeColor: const Color(0xFF3F51B5), // Highlight selected boxes
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          controller.toggleMapping(cloId, ploId, val);
                                                        }
                                                      },
                                                    ),
                                                  );
                                                }),
                                              )
                                          );
                                        }),
                                      ]
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          // SAVE BUTTON inside the grid container bottom
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                ),
                                icon: const Icon(Icons.save, color: Colors.white, size: 20),
                                label: Obx(() => controller.isLoading.value
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2))
                                ),
                                onPressed: controller.isLoading.value ? null : () {
                                  controller.saveMappings(_extractedCourseId!);
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}