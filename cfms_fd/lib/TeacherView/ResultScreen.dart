import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/TeacherController/ResultContoller.dart';


class ResultScreen extends StatefulWidget {
  final String token;
  const ResultScreen({super.key, required this.token});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ResultController controller;

  String? _selectedAllocId;
  String? _selectedAssessmentId;
  String? _selectedQuestionId;

  String _courseInfo = "";
  String _batchInfo = "";
  String _sectionInfo = "";
  String _assessmentTypeInfo = "";
  int _questionTotalMarks = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ResultController(token: widget.token));
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await controller.fetchAllocations();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _selectedAllocId = null;
      _selectedAssessmentId = null;
      _selectedQuestionId = null;
      _questionTotalMarks = 0;
    });
    controller.assessments.clear();
    controller.questions.clear();
    controller.results.clear();
    await _loadInitialData();
  }

  void _showEditDialog(dynamic result) {
    TextEditingController editMarks = TextEditingController(text: result['obtained_marks'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Obtained Marks', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editMarks,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: 'Marks (Out of $_questionTotalMarks)',
                border: const OutlineInputBorder()
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              onPressed: () async {
                int enteredMarks = int.tryParse(editMarks.text) ?? 0;
                if (enteredMarks > _questionTotalMarks) {
                  Get.snackbar("Invalid Input", "Obtained marks cannot exceed total marks ($_questionTotalMarks).", backgroundColor: Colors.orange, colorText: Colors.white);
                  return;
                }
                Navigator.pop(context);
                await controller.updateSingleResult(result['id'], enteredMarks, _selectedQuestionId!);
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. ALLOCATED COURSES
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
                                  _selectedQuestionId = null;
                                  _questionTotalMarks = 0;
                                  controller.results.clear();

                                  var alloc = controller.allocations.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                  if (alloc != null) {
                                    _courseInfo = alloc['course_offered']?['course']?['course_name'] ?? 'Unknown';
                                    _sectionInfo = alloc['section'] ?? 'N/A';
                                    _batchInfo = alloc['batch']?['batch_name'] ?? 'N/A';
                                  }
                                });
                                if (val != null) {
                                  controller.fetchAssessments(val);
                                  controller.fetchEnrolledStudents(val);
                                }
                              },
                            )),
                            const SizedBox(height: 14),

                            // 2. ASSESSMENT
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
                                setState(() {
                                  _selectedAssessmentId = val;
                                  _selectedQuestionId = null;
                                  _questionTotalMarks = 0;
                                  controller.results.clear();

                                  var assm = controller.assessments.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                  if(assm != null) _assessmentTypeInfo = assm['type'] ?? 'Unknown';
                                });
                                if (val != null) controller.fetchQuestions(val);
                              },
                            )),
                            const SizedBox(height: 14),

                            // 3. QUESTIONS
                            Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedQuestionId,
                              dropdownColor: const Color(0xFF1E3C72),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Select Question", Icons.help_outline),
                              hint: const Text("Select Question", style: TextStyle(color: Colors.white70)),
                              items: controller.questions.map((q) => DropdownMenuItem(
                                value: q['id'].toString(),
                                child: Text(q['question_text'] ?? 'No text', style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedQuestionId = val;
                                  var qObj = controller.questions.firstWhere((e) => e['id'].toString() == val, orElse: () => null);
                                  if(qObj != null) {
                                    _questionTotalMarks = int.tryParse(qObj['total_marks'].toString()) ?? 0;
                                  }
                                });
                                if (val != null) controller.fetchResults(val);
                              },
                            )),
                            const SizedBox(height: 14),

                            if (_selectedQuestionId != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                                  child: Text("Total Marks For This Question: $_questionTotalMarks", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),

                            // 4. ENTER MARKS BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: _selectedQuestionId == null ? null : () {
                                  if (controller.enrolledStudents.isEmpty) {
                                    Get.snackbar("Info", "No students are enrolled in this allocation.", backgroundColor: Colors.orange, colorText: Colors.white);
                                    return;
                                  }
                                  Get.to(() => MarksEntryScreen(
                                    controller: controller,
                                    questionId: _selectedQuestionId!,
                                    totalMarks: _questionTotalMarks,
                                    courseInfo: _courseInfo,
                                    batchInfo: _batchInfo,
                                    sectionInfo: _sectionInfo,
                                    assessmentType: _assessmentTypeInfo,
                                  ));
                                },
                                child: const Text("ENTER OBTAINED MARKS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- DATA GRID (SAVED RESULTS) ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 580,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A237E),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 130, child: Text("Reg No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              SizedBox(width: 250, child: Text("Student Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              SizedBox(width: 80, child: Text("Obt Marks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              // ✨ FIX: Delete hatne ke baad grid mein space theek kar diya
                              SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        Container(
                          width: 580,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                          child: Obx(() {
                            if (controller.isLoading.value && controller.results.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))));
                            }
                            if (_selectedQuestionId == null) {
                              return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Select a question to view results.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                            }
                            if (controller.results.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No marks entered yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.results.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                              itemBuilder: (_, i) {
                                var res = controller.results[i];
                                String regNo = res['student']?['reg_no'] ?? 'N/A';
                                String stdName = res['student']?['std_name'] ?? 'Unknown';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 130, child: Text(regNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                      SizedBox(width: 250, child: Text(stdName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E3C72)))),
                                      SizedBox(width: 80, child: Text(res['obtained_marks'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center, // ✨ FIX: Sirf center mein Edit dikhega
                                          children: [
                                            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit, size: 20, color: Colors.indigo), onPressed: () => _showEditDialog(res)),
                                            // ✨ FIX: Delete button remove kar diya hai!
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

// =========================================================================================
// SCREEN 2: MARKS ENTRY SCREEN (Shows Enrolled Students Grid)
// =========================================================================================
class MarksEntryScreen extends StatefulWidget {
  final ResultController controller;
  final String questionId;
  final int totalMarks;
  final String courseInfo;
  final String batchInfo;
  final String sectionInfo;
  final String assessmentType;

  const MarksEntryScreen({
    super.key,
    required this.controller,
    required this.questionId,
    required this.totalMarks,
    required this.courseInfo,
    required this.batchInfo,
    required this.sectionInfo,
    required this.assessmentType,
  });

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final Map<int, TextEditingController> marksControllers = {};
  final Map<int, bool> hasExistingMark = {}; // ✨ FIX: Lock state maintain karne ke liye

  @override
  void initState() {
    super.initState();

    // ✨ FIX: Pehle check karte hain kin bacchon ke marks pehle se exist karte hain
    Map<int, String> existingMarksMap = {};
    for (var r in widget.controller.results) {
      existingMarksMap[r['student_id']] = r['obtained_marks'].toString();
    }

    // Initialize text controllers
    for (var std in widget.controller.enrolledStudents) {
      int stdId = std['id'];
      String existingMark = existingMarksMap[stdId] ?? '';

      marksControllers[stdId] = TextEditingController(text: existingMark);
      hasExistingMark[stdId] = existingMark.isNotEmpty; // Agar marks hain toh ReadOnly true ho jaye
    }
  }

  @override
  void dispose() {
    marksControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  void _saveData() async {
    Map<String, String> marksDataToSave = {};
    bool hasInvalidMarks = false;
    bool hasEmptyMarks = false;

    marksControllers.forEach((studentId, txtCtrl) {
      String text = txtCtrl.text.trim();

      // ✨ FIX: Strict Check - Agar ek bhi bacchay ke marks khali hain toh error
      if (text.isEmpty) {
        hasEmptyMarks = true;
      } else {
        int entered = int.tryParse(text) ?? 0;
        if (entered > widget.totalMarks) {
          hasInvalidMarks = true;
        } else {
          marksDataToSave[studentId.toString()] = entered.toString();
        }
      }
    });

    // Error messages trigger karna
    if (hasEmptyMarks) {
      Get.snackbar("Incomplete", "Please enter marks for ALL enrolled students before saving.", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (hasInvalidMarks) {
      Get.snackbar("Invalid Input", "Some obtained marks exceed the total marks (${widget.totalMarks}). Please fix them.", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (marksDataToSave.isEmpty) {
      return;
    }

    bool success = await widget.controller.saveBulkResults(widget.questionId, marksDataToSave);
    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Enter Marks", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Information Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3C72),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Course: ${widget.courseInfo}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Batch: ${widget.batchInfo} | Section: ${widget.sectionInfo}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text("Assessment: ${widget.assessmentType} (Total: ${widget.totalMarks})", style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Enrolled Students Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 530,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 130, child: Text("Reg No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        SizedBox(width: 250, child: Text("Student Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        SizedBox(width: 100, child: Text("Obt Marks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  Container(
                    width: 530,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)), border: Border.all(color: Colors.grey[300]!)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.controller.enrolledStudents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (_, i) {
                        var std = widget.controller.enrolledStudents[i];
                        int stdId = std['id'];
                        bool isLocked = hasExistingMark[stdId]!; // ✨ FIX: Lock Check

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 130, child: Text(std['reg_no'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              SizedBox(width: 250, child: Text(std['std_name'] ?? 'Unknown', style: const TextStyle(fontSize: 14, color: Colors.black87))),
                              SizedBox(
                                width: 100,
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: marksControllers[stdId],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    readOnly: isLocked, // ✨ FIX: Edit disable kar diya
                                    decoration: InputDecoration(
                                      filled: isLocked, // Background grey ho jayega
                                      fillColor: isLocked ? Colors.grey[200] : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      hintText: '0',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Save Button docked at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saveData,
                child: Obx(() => widget.controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE RESULTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5))
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}