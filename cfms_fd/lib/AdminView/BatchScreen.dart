import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/BatchController.dart';

class BatchScreen extends StatefulWidget {
  final String token;
  const BatchScreen({super.key, required this.token});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final BatchController _batchController = BatchController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _batchNameController = TextEditingController();
  int? _selectedProgramId;
  int? _selectedDepartmentId;

  List<dynamic> _batches = [];
  List<dynamic> _programs = [];
  List<dynamic> _departments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    super.dispose();
  }

  // Fetch batches, programs, and departments from database simultaneously
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final batchResult = await _batchController.fetchBatches(widget.token);
    final programResult = await _batchController.fetchPrograms(widget.token);
    final departmentResult = await _batchController.fetchDepartments(widget.token);

    if (mounted) {
      setState(() {
        if (programResult['success'] == true) {
          _programs = programResult['data'] ?? [];
        } else {
          _programs = [];
          _showToast(programResult['message'] ?? 'Error fetching database programs.', Colors.red);
        }

        if (departmentResult['success'] == true) {
          _departments = departmentResult['data'] ?? [];
        } else {
          _departments = [];
          _showToast(departmentResult['message'] ?? 'Error fetching database departments.', Colors.red);
        }

        if (batchResult['success'] == true) {
          _batches = batchResult['data'] ?? [];
        } else {
          _showToast(batchResult['message'] ?? 'Error fetching batches from database.', Colors.red);
        }
        _isLoading = false;
      });
    }
  }

  // ---------- Safe integer formatting logic ----------
  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  // ---------- GETTER: Filter Programs Dropdown based on Selected Department ----------
  List<dynamic> get _getFilteredProgramsForDropdown {
    if (_selectedDepartmentId == null) return _programs;
    return _programs.where((prog) {
      final deptId = _toInt(prog['department_id']);
      return deptId == _selectedDepartmentId;
    }).toList();
  }

  // ---------- GETTER: Cascade Department Filter via program_id ----------
  List<dynamic> get _filteredBatches {
    List<dynamic> list = _batches;

    if (_selectedDepartmentId != null) {
      list = list.where((batch) {
        // 1. Direct object relation check
        if (batch['program'] != null && batch['program']['department_id'] != null) {
          final nestedDeptId = _toInt(batch['program']['department_id']);
          if (nestedDeptId == _selectedDepartmentId) return true;
        }

        // 2. Pure database-style program_id mapping lookup (Null-safe)
        final progId = _toInt(batch['program_id']);
        final matches = _programs.where((p) => _toInt(p['id']) == progId);
        final matchedProg = matches.isNotEmpty ? matches.first : null;

        if (matchedProg != null && matchedProg['department_id'] != null) {
          final deptId = _toInt(matchedProg['department_id']);
          return deptId == _selectedDepartmentId;
        }

        return false;
      }).toList();
    }

    // Filter table dynamically by Program if selected
    if (_selectedProgramId != null) {
      list = list.where((batch) {
        return _toInt(batch['program_id']) == _selectedProgramId;
      }).toList();
    }

    return list;
  }

  // ---------- Build dropdown list items securely (With Anti-N/A Key Scanner) ----------
  List<DropdownMenuItem<int>> _buildItems(List<dynamic> list, String primaryKey, String fallbackKey) {
    final seen = <int>{};
    final items = <DropdownMenuItem<int>>[];

    for (var item in list) {
      if (item == null) continue;
      final id = _toInt(item['id']);
      if (id == null) continue;
      if (!seen.add(id)) continue;

      // Anti-N/A Deep Key Fallback Array Scanner
      String label = 'N/A';
      for (var key in [primaryKey, fallbackKey, 'name', 'department_name', 'dept_name', 'title', 'program_name']) {
        if (item[key] != null && item[key].toString().trim().isNotEmpty) {
          label = item[key].toString();
          break;
        }
      }

      items.add(DropdownMenuItem<int>(
        value: id,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ));
    }
    return items;
  }

  // ---------- Cross-validate dropdown values safely ----------
  int? _validValue(int? selected, List<DropdownMenuItem<int>> items) {
    if (selected == null) return null;
    final exists = items.any((item) => item.value == selected);
    return exists ? selected : null;
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ---------- Trigger Edit Modal Dialog Flow ----------
  void _showEditDialog(Map<String, dynamic> currentBatch) {
    final _editFormKey = GlobalKey<FormState>();
    final TextEditingController _editNameController = TextEditingController(
      text: currentBatch['batch_name']?.toString() ?? '',
    );

    final progItems = _buildItems(_programs, 'name', 'program_name');
    int? _editProgramId = _validValue(_toInt(currentBatch['program_id']), progItems);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Edit Batch Info', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Form(
                  key: _editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _editProgramId,
                        dropdownColor: const Color(0xFF2A5298),
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Choose Program',
                          border: OutlineInputBorder(),
                        ),
                        items: _programs.map<DropdownMenuItem<int>>((program) {
                          String title = 'Unknown';
                          for (var key in ['name', 'program_name', 'title', 'dept_name']) {
                            if (program[key] != null) {
                              title = program[key].toString();
                              break;
                            }
                          }
                          return DropdownMenuItem<int>(
                            value: _toInt(program['id']),
                            child: Text(title, style: const TextStyle(color: Colors.black87)),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => _editProgramId = val),
                        validator: (value) => value == null ? 'Please select a program.' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _editNameController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Name',
                          hintText: 'yyyy-yyyy',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Field is required.';
                          if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(value.trim())) return 'Format: yyyy-yyyy';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                    onPressed: () async {
                      if (_editFormKey.currentState!.validate()) {
                        // Duplicate Check scoped strictly to the selected program (Excludes current row ID)
                        final inputName = _editNameController.text.trim().toLowerCase();
                        final currentId = currentBatch['id'].toString();
                        bool isDuplicate = _batches.any((b) =>
                        (b['batch_name'] ?? '').toString().trim().toLowerCase() == inputName &&
                            _toInt(b['program_id']) == _editProgramId &&
                            b['id'].toString() != currentId);

                        if (isDuplicate) {
                          _showToast("A batch with this name already exists in this program.", Colors.red);
                          return;
                        }

                        Navigator.pop(context);
                        setState(() => _isLoading = true);

                        final result = await _batchController.updateBatch(
                          widget.token,
                          _toInt(currentBatch['id']) ?? 0,
                          _editNameController.text.trim(),
                          _editProgramId!.toString(),
                        );

                        if (result['success'] == true) {
                          _showToast('Batch modified successfully!', Colors.green);
                        } else {
                          _showToast(result['message'] ?? 'Modification failed.', Colors.red);
                        }
                        await _loadData();
                      }
                    },
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptItems = _buildItems(_departments, 'name', 'department_name');
    final reactiveProgItems = _buildItems(_getFilteredProgramsForDropdown, 'name', 'program_name');
    final activeFilteredBatches = _filteredBatches;

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
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Glassmorphic Input Form Panel
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
                              // 1. DEPARTMENT DROPDOWN
                              DropdownButtonFormField<int>(
                                value: _validValue(_selectedDepartmentId, deptItems),
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
                                    _selectedDepartmentId = val;
                                    _selectedProgramId = null; // Clean downstream hierarchy selection
                                  });
                                },
                              ),
                              const SizedBox(height: 14),

                              // 2. PROGRAM DROPDOWN
                              DropdownButtonFormField<int>(
                                value: _validValue(_selectedProgramId, reactiveProgItems),
                                dropdownColor: const Color(0xFF2A5298),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                hint: const Text("Select Program", style: TextStyle(color: Colors.white70)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.school, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                items: reactiveProgItems,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedProgramId = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 14),

                              // 3. BATCH NAME INPUT
                              TextFormField(
                                controller: _batchNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Batch Name",
                                  hintText: "yyyy-yyyy",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.date_range, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Batch timeframe is required.';
                                  if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(value.trim())) return 'Use exact format: yyyy-yyyy';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // ADD BATCH BUTTON PANEL (Full Width - No Clear Button)
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
                                    if (_selectedProgramId == null) {
                                      _showToast("Please select a Program.", Colors.orange);
                                      return;
                                    }
                                    if (!_formKey.currentState!.validate()) return;

                                    // Duplicate Check scoped strictly to the selected program
                                    final inputName = _batchNameController.text.trim().toLowerCase();
                                    bool isDuplicate = _batches.any((b) =>
                                    (b['batch_name'] ?? '').toString().trim().toLowerCase() == inputName &&
                                        _toInt(b['program_id']) == _selectedProgramId
                                    );

                                    if (isDuplicate) {
                                      _showToast("A batch with this name already exists in this program.", Colors.red);
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    final result = await _batchController.createBatch(
                                      widget.token,
                                      _batchNameController.text.trim(),
                                      _selectedProgramId!.toString(),
                                    );

                                    if (result['success'] == true) {
                                      _showToast("Batch created successfully!", Colors.green);
                                      _batchNameController.clear();
                                      setState(() {
                                        _selectedProgramId = null;
                                        _selectedDepartmentId = null;
                                      });
                                      await _loadData();
                                    } else {
                                      _showToast(result['message'] ?? "Failed to create batch.", Colors.red);
                                      setState(() => _isLoading = false);
                                    }
                                  },
                                  child: const Text("ADD BATCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Grid Table Header (Two Clean Columns Only)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.9),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(child: Text("Batch Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        SizedBox(width: 90, child: Text("Actions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),

                  // Grid Table Content Render Block (Two Columns)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    child: activeFilteredBatches.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500))))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: activeFilteredBatches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                      itemBuilder: (_, i) {
                        var batch = activeFilteredBatches[i];
                        String displayBatchName = (batch['batch_name'] ?? 'N/A').toString();

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(child: Text(displayBatchName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14))),
                              SizedBox(
                                width: 90,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.edit, color: Colors.indigo, size: 22),
                                      onPressed: () => _showEditDialog(batch),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        final bId = _toInt(batch['id']) ?? 0;
                                        final result = await _batchController.deleteBatch(widget.token, bId);
                                        await _loadData();

                                        if (mounted) {
                                          bool success = result['success'] == true;
                                          _showToast(
                                              success ? 'Batch deleted successfully.' : 'Failed to delete batch.',
                                              success ? Colors.green : Colors.redAccent
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
}