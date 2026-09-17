import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ViewModel/Controller/TeacherController/AssessmentController.dart';

class AssessmentScreen extends StatefulWidget {
  final String token;
  const AssessmentScreen({super.key, required this.token});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late AssessmentController controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _weightController = TextEditingController();
  String? _selectedAllocId;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AssessmentController(token: widget.token));
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await controller.fetchAllocations();
  }

  // ✨ FIX: Refresh par Dropdowns aur form ko clear karne ki logic add ki gayi hai
  Future<void> _handleRefresh() async {
    setState(() {
      _selectedAllocId = null;
      _selectedType = null;
      _weightController.clear();
    });
    controller.assessments.clear(); // Purane table data ko bhi clear kar dega
    await controller.fetchAllocations();
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showEditDialog(dynamic assessment) {
    final TextEditingController _editWeightController = TextEditingController(text: assessment['weightage'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Weightage', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _editWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New Weightage (%)', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              onPressed: () async {
                Navigator.pop(context);
                await controller.updateAssessment(
                    assessment['id'],
                    _selectedAllocId!,
                    int.tryParse(_editWeightController.text) ?? 0
                );
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
                  // --- INPUT FORM PANEL ---
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
                            children: [
                              Obx(() => DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedAllocId,
                                dropdownColor: const Color(0xFF1E3C72),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Select Course",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.menu_book, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                hint: controller.isLoading.value && controller.allocations.isEmpty
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : const Text("Select Course", style: TextStyle(color: Colors.white70)),
                                items: controller.allocations.map((a) {
                                  String courseName = a['course_offered']?['course']?['course_name'] ?? 'Unknown Course';
                                  String sessionName = a['session']?['s_name'] ?? 'Unknown Session';
                                  String section = a['section'] ?? 'N/A';

                                  return DropdownMenuItem(
                                    value: a['id'].toString(),
                                    child: Text(
                                      "$courseName - $sessionName ($section)",
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedAllocId = val);
                                  if (val != null) {
                                    controller.fetchAssessments(val);
                                  }
                                },
                                validator: (val) => val == null ? 'Required' : null,
                              )),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _selectedType, // ✨ FIX: Connected value properly
                                dropdownColor: const Color(0xFF1E3C72),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Assessment Type",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.assignment, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                items: controller.assessmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                                onChanged: (val) => setState(() => _selectedType = val),
                                validator: (val) => val == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _weightController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Weightage (%)",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.percent, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                validator: (val) => (val == null || int.tryParse(val) == null) ? 'Invalid weight' : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () async {
                                    if (!_formKey.currentState!.validate() || _selectedAllocId == null || _selectedType == null) return;
                                    await controller.saveAssessment(_selectedAllocId!, _selectedType!, int.parse(_weightController.text));
                                  },
                                  child: const Text("SAVE ASSESSMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- DATA GRID ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("Type", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text("Weight", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                    child: Obx(() {
                      if (controller.isLoading.value && controller.assessments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
                        );
                      }
                      if (controller.assessments.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("No assessments added.")));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.assessments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          var item = controller.assessments[i];
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(flex: 2, child: Text(item['type'])),
                                Expanded(flex: 1, child: Text("${item['weightage']}%", textAlign: TextAlign.center)),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                                          onPressed: () => _showEditDialog(item)),
                                      IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                          onPressed: () => controller.deleteAssessment(item['id'], _selectedAllocId!)),
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
          ),
        ],
      ),
    );
  }
}