import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/PLOsController.dart';

class PLOsScreen extends StatefulWidget {
  final String token;
  const PLOsScreen({super.key, required this.token});

  @override
  State<PLOsScreen> createState() => _PLOsScreenState();
}

class _PLOsScreenState extends State<PLOsScreen> {
  final PLOsController _controller = PLOsController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final GlobalKey<FormFieldState> _deptDropdownKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _progDropdownKey = GlobalKey<FormFieldState>();

  List<dynamic> _allPLOs = [];
  List<dynamic> _filteredPLOs = [];
  List<dynamic> _deptList = [];
  List<dynamic> _allPrograms = [];
  List<dynamic> _filteredPrograms = [];

  int? _selectedDeptId;
  int? _selectedProgId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _codeController.text = "PLO_";
    _codeController.addListener(_handlePrefixStability);
    _loadAllData();
  }

  void _handlePrefixStability() {
    if (!_codeController.text.startsWith("PLO_")) {
      _codeController.removeListener(_handlePrefixStability);
      _codeController.text = "PLO_";
      _codeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _codeController.text.length),
      );
      _codeController.addListener(_handlePrefixStability);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_handlePrefixStability);
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var plos = await _controller.fetchPLOs(widget.token);
    var depts = await _controller.fetchDepartments(widget.token);
    var progs = await _controller.fetchPrograms(widget.token);

    if (!mounted) return;
    setState(() {
      _allPLOs = plos;
      _deptList = depts;
      _allPrograms = progs;
      _applyFilters();
      _isLoading = false;
    });
  }

  // Pull to Refresh Handler
  Future<void> _handleRefresh() async {
    setState(() {
      _selectedDeptId = null;
      _selectedProgId = null;
      _deptDropdownKey.currentState?.reset();
      _progDropdownKey.currentState?.reset();
    });
    await _loadAllData();
  }

  void _applyFilters() {
    setState(() {
      if (_selectedDeptId != null) {
        _filteredPrograms = _allPrograms.where((p) {
          return p['department_id'] == _selectedDeptId;
        }).toList();
      } else {
        _filteredPrograms = List.from(_allPrograms);
      }

      _filteredPLOs = _allPLOs.where((plo) {
        bool matchesDept = true;
        bool matchesProg = true;

        if (_selectedDeptId != null) {
          var deptIdFromPlo = plo['program']?['department_id'] ?? plo['department_id'];
          matchesDept = (deptIdFromPlo == _selectedDeptId);
        }
        if (_selectedProgId != null) {
          matchesProg = (plo['program_id'] == _selectedProgId);
        }

        return matchesDept && matchesProg;
      }).toList();
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
                      // Glassmorphic Input Panel
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
                                  key: _deptDropdownKey,
                                  dropdownColor: const Color(0xFF2A5298),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  hint: const Text("Select Department", style: TextStyle(color: Colors.white70)),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.business, color: Colors.white70),
                                  ),
                                  items: _deptList.map((dynamic d) {
                                    return DropdownMenuItem<int>(
                                      value: d['id'] as int,
                                      child: Text(d['dept_name']?.toString() ?? d['name']?.toString() ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedDeptId = val;
                                      _selectedProgId = null;
                                      _progDropdownKey.currentState?.reset();
                                    });
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(height: 15),
                                DropdownButtonFormField<int>(
                                  key: _progDropdownKey,
                                  dropdownColor: const Color(0xFF2A5298),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  hint: const Text("Select Program", style: TextStyle(color: Colors.white70)),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.school, color: Colors.white70),
                                  ),
                                  items: _filteredPrograms.map((dynamic p) {
                                    return DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(p['program_name']?.toString() ?? p['name']?.toString() ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedProgId = val);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _codeController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "PLO Code Suffix",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.qr_code, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _descController,
                                  maxLines: 2,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "PLO Description",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.description, color: Colors.white70),
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
                                      if (_selectedProgId == null || _codeController.text.trim() == "PLO_" || _descController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please fill all required fields properly."), backgroundColor: Colors.orange),
                                        );
                                        return;
                                      }

                                      setState(() => _isLoading = true);
                                      bool success = await _controller.addPLO(
                                        _codeController.text.trim(),
                                        _descController.text.trim(),
                                        _selectedProgId!,
                                        widget.token,
                                      );

                                      if (success) {
                                        _codeController.text = "PLO_";
                                        _descController.clear();
                                        _loadAllData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("PLO configured successfully."), backgroundColor: Colors.green),
                                        );
                                      } else {
                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Process failed. Duplicate entries are restricted inside the same scope."), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    },
                                    child: const Text("ADD PLO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Table Layout Headers Section with Dividers
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.9),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text("PLO Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            Expanded(flex: 5, child: Text("Description", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),

                      // Table Data Grid List View Area with Vertical and Horizontal Borders
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                            : _filteredPLOs.isEmpty
                            ? const Center(child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)))
                            : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredPLOs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(_filteredPLOs[i]['plo_code'] ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13))),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                Expanded(flex: 5, child: Text(_filteredPLOs[i]['plo_description'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis)),
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
                                        onPressed: () => _editPLODialog(_filteredPLOs[i]),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          bool success = await _controller.deletePLO(_filteredPLOs[i]['id'], widget.token);
                                          _loadAllData();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(success ? 'PLO deleted successfully.' : 'Failed to delete PLO due to operational constraints.'),
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

  void _editPLODialog(Map<String, dynamic> plo) {
    TextEditingController editCodeController = TextEditingController(text: plo['plo_code']);
    TextEditingController editDescController = TextEditingController(text: plo['plo_description']);
    int? editProgId = plo['program_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Modify Configuration Record", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: editProgId,
                decoration: const InputDecoration(labelText: "Target Scope Program", border: OutlineInputBorder()),
                items: _allPrograms.map((dynamic p) => DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['program_name'] ?? p['name'] ?? ''))).toList(),
                onChanged: (val) => editProgId = val,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: editCodeController,
                decoration: const InputDecoration(labelText: "PLO Code", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: editDescController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Content Description", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
            onPressed: () async {
              if (editProgId != null) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                bool success = await _controller.updatePLO(plo['id'], editCodeController.text.trim(), editDescController.text.trim(), editProgId!, widget.token);
                _loadAllData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'PLO updated successfully.' : 'Failed to update PLO.'),
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
    );
  }
}