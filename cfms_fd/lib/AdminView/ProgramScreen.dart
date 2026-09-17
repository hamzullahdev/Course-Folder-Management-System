import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/ProgramController.dart';

class ProgramScreen extends StatefulWidget {
  final String token;
  const ProgramScreen({super.key, required this.token});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final ProgramController _controller = ProgramController();
  final TextEditingController _nameController = TextEditingController();

  final GlobalKey<FormFieldState> _dropdownKey = GlobalKey<FormFieldState>();

  List<dynamic> _allPrograms = [];
  List<dynamic> _filteredPrograms = [];
  List<dynamic> _deptList = [];
  int? _selectedDeptId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var progs = await _controller.fetchPrograms(widget.token);
    var depts = await _controller.fetchDepartments(widget.token);

    if (!mounted) return;
    setState(() {
      _allPrograms = progs;
      _deptList = depts;
      _applyFilters();
      _isLoading = false;
    });
  }

  // Pull to Refresh Handler
  Future<void> _handleRefresh() async {
    setState(() {
      _selectedDeptId = null;
      _dropdownKey.currentState?.reset();
      _nameController.clear();
    });
    await _loadData();
  }

  // Real-time grid sorting filtering based on dropdown context
  void _applyFilters() {
    setState(() {
      if (_selectedDeptId != null) {
        _filteredPrograms = _allPrograms.where((prog) {
          final deptId = int.tryParse(prog['department_id']?.toString() ?? '');
          return deptId == _selectedDeptId;
        }).toList();
      } else {
        _filteredPrograms = List.from(_allPrograms);
      }
    });
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
                      // Glassmorphic Control Panel Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<int>(
                                  key: _dropdownKey,
                                  dropdownColor: const Color(0xFF2A5298),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  hint: const Text("Select Department", style: TextStyle(color: Colors.white70)),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.business, color: Colors.white70),
                                  ),
                                  items: _deptList.map((dynamic d) {
                                    final id = int.tryParse(d['id']?.toString() ?? '');
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(d['dept_name']?.toString() ?? d['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedDeptId = val);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Program Name",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.school, color: Colors.white70),
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
                                      if (_selectedDeptId == null || _nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please fill all required fields properly."), backgroundColor: Colors.orange),
                                        );
                                        return;
                                      }

                                      // Duplicate Validation Pre-check Logic
                                      final String inputName = _nameController.text.trim().toLowerCase();
                                      bool isDuplicate = _allPrograms.any((prog) {
                                        final int? deptId = int.tryParse(prog['department_id']?.toString() ?? '');
                                        final String progName = (prog['program_name']?.toString() ?? '').trim().toLowerCase();
                                        return deptId == _selectedDeptId && progName == inputName;
                                      });

                                      if (isDuplicate) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("This program name already exists in the selected department."), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      setState(() => _isLoading = true);
                                      bool success = await _controller.addProgram(_nameController.text.trim(), _selectedDeptId!, widget.token);

                                      if (success) {
                                        _nameController.clear();
                                        _dropdownKey.currentState?.reset();
                                        setState(() => _selectedDeptId = null);
                                        _loadData();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Program configured successfully."), backgroundColor: Colors.green),
                                          );
                                        }
                                      } else {
                                        setState(() => _isLoading = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Process failed. Duplicate entries are restricted inside the same scope."), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text("ADD PROGRAM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Modern Grid Header Layout with Thin Line Dividers
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.9),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text("Dept", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            Expanded(flex: 3, child: Text("Programs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),

                      // Modern Scrolling Grid Body View Component Area
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                            : _filteredPrograms.isEmpty
                            ? const Center(child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)))
                            : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredPrograms.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(_filteredPrograms[i]['department']?['dept_name'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13))),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                Expanded(flex: 3, child: Text(_filteredPrograms[i]['program_name'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
                                        onPressed: () => _editProgram(_filteredPrograms[i]),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          bool success = await _controller.deleteProgram(_filteredPrograms[i]['id'], widget.token);
                                          _loadData();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(success ? 'Program deleted successfully.' : 'Failed to delete program due to operational constraints.'),
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
                          ),
                        ),
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

  void _editProgram(Map<String, dynamic> prog) {
    TextEditingController editNameController = TextEditingController(text: prog['program_name']);
    int? editDeptId = prog['department_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Modify Configuration Record", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: editDeptId,
                decoration: const InputDecoration(labelText: "Target Scope Department", border: OutlineInputBorder()),
                items: _deptList.map((dynamic d) {
                  final id = int.tryParse(d['id']?.toString() ?? '');
                  return DropdownMenuItem<int>(value: id, child: Text(d['dept_name']?.toString() ?? d['name']?.toString() ?? ''));
                }).toList(),
                onChanged: (val) => setModalState(() => editDeptId = val),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(labelText: "Program Name", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              onPressed: () async {
                if (editDeptId != null) {
                  // Duplicate Validation Pre-check for Editing Context
                  final String inputName = editNameController.text.trim().toLowerCase();
                  bool isDuplicate = _allPrograms.any((p) {
                    final int? deptId = int.tryParse(p['department_id']?.toString() ?? '');
                    final String progName = (p['program_name']?.toString() ?? '').trim().toLowerCase();
                    // Exclude the current program record itself from the validation matrix
                    return deptId == editDeptId && progName == inputName && p['id'] != prog['id'];
                  });

                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("This program name already exists in the selected department."), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  bool success = await _controller.updateProgram(prog['id'], editNameController.text.trim(), editDeptId!, widget.token);
                  _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Program updated successfully.' : 'Failed to update program.'),
                        backgroundColor: success ? Colors.green : Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}