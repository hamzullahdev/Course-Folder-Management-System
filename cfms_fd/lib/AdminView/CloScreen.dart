import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/CloController.dart';

class CloScreen extends StatefulWidget {
  final String token;
  const CloScreen({super.key, required this.token});

  @override
  State<CloScreen> createState() => _CloScreenState();
}

class _CloScreenState extends State<CloScreen> {
  final CloController _controller = CloController();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<dynamic> _departments = [];
  List<dynamic> _programs = [];
  List<dynamic> _courses = [];
  List<dynamic> _sessions = [];
  List<dynamic> _clos = [];

  int? _selectedDeptId;
  int? _selectedProgramId;
  int? _selectedCourseId;
  int? _selectedSessionId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    var depts = await _controller.fetchDepartments(widget.token);
    var progs = await _controller.fetchPrograms(widget.token);
    var courses = await _controller.fetchCourses(widget.token);
    var sessions = await _controller.fetchSessions(widget.token);
    var clos = await _controller.fetchClos(widget.token);

    if (mounted) {
      setState(() {
        _departments = depts;
        _programs = progs;
        _courses = courses;
        _sessions = sessions;
        _clos = clos;
        _isLoading = false;
      });
    }
  }

  // ✨ NEW: Pull-down refresh handler to clear session, code, and description
  Future<void> _handleRefresh() async {
    setState(() {
      _selectedDeptId = null;
      _selectedProgramId = null;
      _selectedCourseId = null;
      _selectedSessionId = null; // Session cleared
    });
    _codeController.clear(); // CLO Code cleared
    _descController.clear(); // Description cleared

    await _loadData();
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  List<dynamic> get _visiblePrograms {
    if (_selectedDeptId == null) return [];
    return _programs.where((p) {
      final deptId = _toInt(p['department_id']);
      return deptId == _selectedDeptId;
    }).toList();
  }

  List<dynamic> get _visibleCourses {
    if (_selectedProgramId == null) return [];
    return _courses.where((c) {
      final progId = _toInt(c['program_id']);
      return progId == _selectedProgramId;
    }).toList();
  }

  // Filtered and Sorted CLOs
  List<dynamic> get _filteredClos {
    var list = List<dynamic>.from(_clos);

    if (_selectedDeptId != null) {
      var targetProgIds = _programs.where((p) => _toInt(p['department_id']) == _selectedDeptId).map((p) => _toInt(p['id'])).toSet();
      var targetCourseIds = _courses.where((c) => targetProgIds.contains(_toInt(c['program_id']))).map((c) => _toInt(c['id'])).toSet();
      list = list.where((c) => targetCourseIds.contains(_toInt(c['course_id']))).toList();
    }

    if (_selectedProgramId != null) {
      var targetCourseIds = _courses.where((c) => _toInt(c['program_id']) == _selectedProgramId).map((c) => _toInt(c['id'])).toSet();
      list = list.where((c) => targetCourseIds.contains(_toInt(c['course_id']))).toList();
    }

    if (_selectedCourseId != null) {
      list = list.where((c) => _toInt(c['course_id']) == _selectedCourseId).toList();
    }

    if (_selectedSessionId != null) {
      list = list.where((c) => _toInt(c['session_id']) == _selectedSessionId).toList();
    }

    // Sort logically ascending based on numbers inside the string
    list.sort((a, b) {
      String codeA = a['clos_code']?.toString() ?? '';
      String codeB = b['clos_code']?.toString() ?? '';

      int numA = int.tryParse(codeA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB = int.tryParse(codeB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      return numA.compareTo(numB);
    });

    return list;
  }

  List<DropdownMenuItem<int>> _buildItems(List<dynamic> list, String primaryKey, String fallbackKey) {
    final seen = <int>{};
    final items = <DropdownMenuItem<int>>[];

    for (var item in list) {
      final id = _toInt(item['id']);
      if (id == null) continue;
      if (!seen.add(id)) continue;

      final label = item[primaryKey]?.toString() ?? item[fallbackKey]?.toString() ?? 'N/A';

      items.add(DropdownMenuItem<int>(
        value: id,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ));
    }
    return items;
  }

  int? _validValue(int? selected, List<DropdownMenuItem<int>> items) {
    if (selected == null) return null;
    final exists = items.any((item) => item.value == selected);
    return exists ? selected : null;
  }

  @override
  Widget build(BuildContext context) {
    final deptItems = _buildItems(_departments, 'dept_name', 'name');
    final progItems = _buildItems(_visiblePrograms, 'program_name', 'name');
    final courseItems = _buildItems(_visibleCourses, 'course_name', 'name');
    final sessionItems = _buildItems(_sessions, 's_name', 'name');

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
              onRefresh: _handleRefresh, // ✨ FIX: Hooked to the new refresh handler
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
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
                          children: [
                            DropdownButtonFormField<int>(
                              value: _validValue(_selectedDeptId, deptItems),
                              dropdownColor: const Color(0xFF2A5298),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              hint: const Text("Select Department", style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.business, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                              items: deptItems,
                              onChanged: (val) {
                                setState(() {
                                  _selectedDeptId = val;
                                  _selectedProgramId = null;
                                  _selectedCourseId = null;
                                  _selectedSessionId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<int>(
                              value: _validValue(_selectedProgramId, progItems),
                              dropdownColor: const Color(0xFF2A5298),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              hint: const Text("Select Program", style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.school, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                              items: progItems,
                              onChanged: _selectedDeptId == null ? null : (val) {
                                setState(() {
                                  _selectedProgramId = val;
                                  _selectedCourseId = null;
                                  _selectedSessionId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<int>(
                              value: _validValue(_selectedCourseId, courseItems),
                              dropdownColor: const Color(0xFF2A5298),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              hint: const Text("Select Course", style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.book, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                              items: courseItems,
                              onChanged: _selectedProgramId == null ? null : (val) {
                                setState(() {
                                  _selectedCourseId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<int>(
                              value: _validValue(_selectedSessionId, sessionItems),
                              dropdownColor: const Color(0xFF2A5298),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              hint: const Text("Select Session", style: TextStyle(color: Colors.white70)),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.date_range, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                              items: sessionItems,
                              onChanged: _selectedCourseId == null ? null : (val) {
                                setState(() {
                                  _selectedSessionId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _codeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "CLO Code (e.g. CLO_1)",
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.assignment_turned_in, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _descController,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "CLO Description",
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.description, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F51B5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                                onPressed: () async {
                                  if (_selectedDeptId == null) {
                                    _showToast("Please select a Department.", Colors.orange);
                                    return;
                                  }
                                  if (_selectedProgramId == null) {
                                    _showToast("Please select a Program.", Colors.orange);
                                    return;
                                  }
                                  if (_selectedCourseId == null) {
                                    _showToast("Please select a Course.", Colors.orange);
                                    return;
                                  }
                                  if (_selectedSessionId == null) {
                                    _showToast("Please select a Session.", Colors.orange);
                                    return;
                                  }
                                  if (_codeController.text.trim().isEmpty) {
                                    _showToast("Please enter a CLO Code.", Colors.orange);
                                    return;
                                  }
                                  if (_descController.text.trim().isEmpty) {
                                    _showToast("Please enter a CLO Description.", Colors.orange);
                                    return;
                                  }

                                  // Local Uniqueness Guard Check
                                  bool isDuplicate = _filteredClos.any((c) => c['clos_code'].toString().toLowerCase() == _codeController.text.trim().toLowerCase());
                                  if (isDuplicate) {
                                    _showToast("This CLO code already exists in the table.", Colors.redAccent);
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  var result = await _controller.addClo(
                                    _codeController.text.trim(),
                                    _descController.text.trim(),
                                    _selectedCourseId!,
                                    _selectedSessionId!,
                                    widget.token,
                                  );

                                  if (result['success'] == true) {
                                    _showToast(result['message'], Colors.green);
                                    _codeController.clear();
                                    _descController.clear();

                                    setState(() {
                                      _selectedDeptId = null;
                                      _selectedProgramId = null;
                                      _selectedCourseId = null;
                                      _selectedSessionId = null;
                                    });
                                    await _loadData();
                                  } else {
                                    _showToast(result['message'] ?? "This CLO code already exists in the table.", Colors.red);
                                    setState(() => _isLoading = false);
                                  }
                                },
                                child: const Text("ADD CLO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.9),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("CLO Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                        Expanded(flex: 3, child: Text("Description", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                        SizedBox(width: 90, child: Text("Actions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    child: _isLoading
                        ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF1A237E))))
                        : _filteredClos.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500))))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _filteredClos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                      itemBuilder: (_, i) {
                        var clo = _filteredClos[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(clo['clos_code'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13))),
                              const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                              Expanded(flex: 3, child: Text(clo['clos_description'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
                                      onPressed: () => _showEditDialog(clo),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        bool success = await _controller.deleteClo(clo['id'], widget.token);
                                        await _loadData();

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success ? 'CLO deleted successfully.' : 'Failed to delete CLO.'),
                                              backgroundColor: success ? Colors.green : Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showEditDialog(Map clo) {
    TextEditingController editCode = TextEditingController(text: clo['clos_code']?.toString() ?? '');
    TextEditingController editDesc = TextEditingController(text: clo['clos_description']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit CLO", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: editCode, decoration: const InputDecoration(labelText: "CLO Code", border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: editDesc, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                  onPressed: () async {
                    if (editCode.text.trim().isEmpty) {
                      _showToast("Please enter a CLO Code.", Colors.orange);
                      return;
                    }
                    if (editDesc.text.trim().isEmpty) {
                      _showToast("Please enter a Description.", Colors.orange);
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    var result = await _controller.updateClo(
                      clo['id'],
                      editCode.text.trim(),
                      editDesc.text.trim(),
                      int.tryParse(clo['course_id']?.toString() ?? '') ?? clo['course_id'],
                      widget.token,
                    );

                    if (result['success'] == true) {
                      _showToast("CLO updated successfully.", Colors.green);
                    } else {
                      _showToast(result['message'] ?? "This CLO code already exists in the table.", Colors.red);
                    }
                    await _loadData();
                  },
                  child: const Text("Update", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
      ),
    );
  }
}