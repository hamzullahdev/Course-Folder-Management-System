import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/TeacherController/QuestionControlller.dart';


class QuestionScreen extends StatefulWidget {
  final String token;
  const QuestionScreen({super.key, required this.token});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late QuestionController controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();

  String? _selectedAllocId;
  String? _selectedAssessmentId;
  dynamic _extractedCourseId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(QuestionController(token: widget.token));
    _loadInitialData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await controller.fetchAllocations();
    await controller.fetchClos(); // Will now hit /admin/clos directly
    await controller.fetchQuestions(); // Loads 'all' for the grid
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _selectedAllocId = null;
      _selectedAssessmentId = null;
      _extractedCourseId = null;
      _textController.clear();
      _marksController.clear();
    });
    controller.selectedCloIds.clear();
    controller.questions.clear();
    await _loadInitialData();
  }

  // ✨ FIX: Deep extraction for Course ID
  dynamic _extractCourseIdSafely(dynamic alloc) {
    if (alloc == null) return null;
    try {
      if (alloc['course_offered'] != null) {
        if (alloc['course_offered']['course'] != null) return alloc['course_offered']['course']['id'];
        if (alloc['course_offered']['course_id'] != null) return alloc['course_offered']['course_id'];
      }
      if (alloc['course'] != null && alloc['course']['id'] != null) return alloc['course']['id'];
      if (alloc['course_id'] != null) return alloc['course_id'];
    } catch (e) {
      debugPrint("Extraction error: $e");
    }
    return null;
  }

  void _showCloDetails(Map clo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(clo['clos_code'] ?? 'CLO Detail', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
        content: Text(clo['clos_description'] ?? 'No description available.', style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _showEditDialog(dynamic question) {
    TextEditingController editText = TextEditingController(text: question['question_text']);
    TextEditingController editMarks = TextEditingController(text: question['total_marks'].toString());

    controller.selectedCloIds.clear();
    if (question['clos'] != null) {
      for (var clo in question['clos']) {
        controller.selectedCloIds.add(int.parse(clo['id'].toString()));
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Question', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: editText,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editMarks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Marks', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text("Map CLOs:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                const SizedBox(height: 8),
                Obx(() {
                  var courseClos = controller.clos.where((c) => c['course_id'].toString() == _extractedCourseId?.toString()).toList();

                  if (courseClos.isEmpty) return const Text("No CLOs mapped for this course.", style: TextStyle(color: Colors.grey, fontSize: 12));

                  return Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: courseClos.map((clo) {
                      int cloId = int.parse(clo['id'].toString());
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: controller.selectedCloIds.contains(cloId),
                            onChanged: (val) => controller.toggleClo(cloId),
                            activeColor: const Color(0xFF1E3C72),
                          ),
                          Text(clo['clos_code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 4),
                            icon: const Icon(Icons.remove_red_eye, color: Color(0xFF3F51B5), size: 18),
                            onPressed: () => _showCloDetails(clo),
                          )
                        ],
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              onPressed: () async {
                if (controller.selectedCloIds.isEmpty) {
                  Get.snackbar("Required", "Please select at least one CLO mapping.", backgroundColor: Colors.orange, colorText: Colors.white);
                  return;
                }
                Navigator.pop(context);
                bool success = await controller.updateQuestion(
                    question['id'],
                    editText.text.trim(),
                    int.tryParse(editMarks.text) ?? 0,
                    controller.selectedCloIds.toList(),
                    _selectedAssessmentId ?? 'all'
                );
                if(success) controller.selectedCloIds.clear();
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) => controller.selectedCloIds.clear());
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
              onRefresh: _handleRefresh,
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // --- GLASSMORPHISM INPUT FORM ---
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. ALLOCATED COURSES DROPDOWN
                              Obx(() => DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedAllocId,
                                dropdownColor: const Color(0xFF1E3C72),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDeco("Select Allocated Course", Icons.menu_book),
                                hint: const Text("Select Course", style: TextStyle(color: Colors.white70)),
                                items: controller.allocations.map((a) {
                                  String courseName = a['course_offered']?['course']?['course_name'] ?? 'Unknown Course';
                                  String sessionName = a['session']?['s_name'] ?? 'Unknown Session';
                                  String section = a['section'] ?? 'N/A';
                                  return DropdownMenuItem(
                                    value: a['id'].toString(),
                                    child: Text("$courseName - $sessionName ($section)", style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAllocId = val;
                                    _selectedAssessmentId = null;

                                    var alloc = controller.allocations.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                    _extractedCourseId = _extractCourseIdSafely(alloc);
                                    controller.selectedCloIds.clear();
                                  });
                                  if (val != null) controller.fetchAssessments(val);
                                },
                                validator: (val) => val == null ? 'Required' : null,
                              )),
                              const SizedBox(height: 14),

                              // 2. ASSESSMENT DROPDOWN
                              Obx(() => DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedAssessmentId,
                                dropdownColor: const Color(0xFF1E3C72),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDeco("Select Assessment", Icons.assignment),
                                hint: const Text("Select Assessment", style: TextStyle(color: Colors.white70)),
                                items: controller.assessments.map((a) => DropdownMenuItem(
                                  value: a['id'].toString(),
                                  child: Text("${a['type']} (${a['weightage']}%)", style: const TextStyle(color: Colors.white)),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedAssessmentId = val);
                                  if (val != null) controller.fetchQuestions(val);
                                },
                                validator: (val) => val == null ? 'Required' : null,
                              )),
                              const SizedBox(height: 14),

                              // 3. QUESTION TEXT
                              TextFormField(
                                controller: _textController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: _inputDeco("Question Text", Icons.text_fields),
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),

                              // 4. MARKS
                              TextFormField(
                                controller: _marksController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco("Total Marks", Icons.score),
                                validator: (val) => (val == null || int.tryParse(val) == null) ? 'Invalid marks' : null,
                              ),
                              const SizedBox(height: 20),

                              // 5. CLO MAPPING SECTION
                              if (_extractedCourseId != null) ...[
                                const Text("Map CLOs (Required):", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                  child: Obx(() {
                                    if (controller.clos.isEmpty) {
                                      return const Text("Loading CLOs or none available in database.", style: TextStyle(color: Colors.white70, fontSize: 13));
                                    }

                                    var courseClos = controller.clos.where((c) => c['course_id'].toString() == _extractedCourseId?.toString()).toList();

                                    if (courseClos.isEmpty) return const Text("No CLOs configured for this specific course in Admin Panel.", style: TextStyle(color: Colors.white70, fontSize: 13));

                                    return Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: courseClos.map((clo) {
                                        int cloId = int.parse(clo['id'].toString());
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: controller.selectedCloIds.contains(cloId),
                                                onChanged: (val) => controller.toggleClo(cloId),
                                                fillColor: MaterialStateProperty.all(Colors.white),
                                                checkColor: const Color(0xFF1E3C72),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(clo['clos_code'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                              icon: const Icon(Icons.remove_red_eye, color: Colors.white70, size: 18),
                                              onPressed: () => _showCloDetails(clo),
                                            )
                                          ],
                                        );
                                      }).toList(),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // 6. SUBMIT BUTTON
                              Obx(() => SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: controller.isLoading.value ? null : () async {
                                    if (!_formKey.currentState!.validate() || _selectedAssessmentId == null) {
                                      Get.snackbar("Alert", "Please fill required fields and select an assessment.", backgroundColor: Colors.orange, colorText: Colors.white);
                                      return;
                                    }

                                    if (controller.selectedCloIds.isEmpty) {
                                      Get.snackbar("Validation Error", "Please map at least one CLO to this question before saving.", backgroundColor: Colors.redAccent, colorText: Colors.white);
                                      return;
                                    }

                                    bool res = await controller.addQuestion(
                                        _selectedAssessmentId!,
                                        _textController.text.trim(),
                                        int.parse(_marksController.text),
                                        controller.selectedCloIds.toList()
                                    );
                                    if (res) {
                                      _textController.clear();
                                      _marksController.clear();
                                    }
                                  },
                                  child: controller.isLoading.value
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text("ADD QUESTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- DATA GRID (HORIZONTALLY SCROLLABLE) ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header
                        Container(
                          width: 850,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A237E),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 400, child: Text("Question Text", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              SizedBox(width: 80, child: Text("Marks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 250, child: Text("CLO Cover", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),

                        // Table Body
                        Container(
                          width: 850,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                          ),
                          child: Obx(() {
                            if (controller.isLoading.value && controller.questions.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))));
                            }
                            if (controller.questions.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No questions available. Add a new question to see it here.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.questions.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                              itemBuilder: (_, i) {
                                var item = controller.questions[i];

                                String mappedClos = "None";
                                if (item['clos'] != null && item['clos'].isNotEmpty) {
                                  List<String> codes = (item['clos'] as List).map((c) => c['clos_code'].toString()).toList();
                                  mappedClos = codes.join(", ");
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: 400,
                                          child: Text(item['question_text'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 5, overflow: TextOverflow.ellipsis)
                                      ),
                                      SizedBox(
                                          width: 80,
                                          child: Text(item['total_marks'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                                      ),
                                      SizedBox(
                                          width: 250,
                                          child: Text(mappedClos, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF1E3C72), fontWeight: FontWeight.bold))
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                                                onPressed: () => _showEditDialog(item)
                                            ),
                                            IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                                onPressed: () => controller.deleteQuestion(item['id'], _selectedAssessmentId)
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
                  ),
                ],
              ),
            ),
          ),
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
}