import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/DepartmentController.dart';

class DepartmentScreen extends StatefulWidget {
  final String token;
  const DepartmentScreen({super.key, required this.token});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final DepartmentController _controller = DepartmentController();
  final TextEditingController _nameController = TextEditingController();
  List<dynamic> _deptList = [];
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
    var data = await _controller.fetchDepartments(widget.token);

    if (!mounted) return;
    setState(() {
      _deptList = data;
      _isLoading = false;
    });
  }

  // Pull to Refresh Handler
  Future<void> _handleRefresh() async {
    setState(() {
      _nameController.clear();
    });
    await _loadData();
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
                      // Glassmorphic Control Panel for Adding Department
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
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Department Name",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    prefixIcon: const Icon(Icons.business, color: Colors.white70),
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
                                      if (_nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please enter a valid department name."), backgroundColor: Colors.orange),
                                        );
                                        return;
                                      }

                                      // Duplicate Check Validation
                                      final String inputName = _nameController.text.trim().toLowerCase();
                                      bool isDuplicate = _deptList.any((dept) =>
                                      (dept['dept_name']?.toString() ?? '').trim().toLowerCase() == inputName
                                      );

                                      if (isDuplicate) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("This department name already exists."), backgroundColor: Colors.redAccent),
                                        );
                                        return;
                                      }

                                      setState(() => _isLoading = true);
                                      bool success = await _controller.addDepartment(_nameController.text.trim(), widget.token);

                                      if (success) {
                                        _nameController.clear();
                                        _loadData();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Department configured successfully."), backgroundColor: Colors.green),
                                          );
                                        }
                                      } else {
                                        setState(() => _isLoading = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Process failed. System rejected entry manipulation."), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text("ADD DEPARTMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Modern Unified Table Header Layout with Thin Lines
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.9),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 5, child: Text("Departments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),

                      // Modern Unified Table Body Component Grid Area
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                            : _deptList.isEmpty
                            ? const Center(child: Text("No records match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)))
                            : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _deptList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    _deptList[i]['dept_name'] ?? '',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                                        onPressed: () => _showEditDialog(_deptList[i]),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          bool success = await _controller.deleteDepartment(_deptList[i]['id'], widget.token);
                                          _loadData();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(success ? 'Department deleted successfully.' : 'Failed to delete record due to operational relational constraints.'),
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

  void _showEditDialog(Map dept) {
    TextEditingController editController = TextEditingController(text: dept['dept_name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Modify Department Scope", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: const InputDecoration(labelText: "Department Name", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;

              // Duplicate Check Validation for Edit Mode Matrix Context
              final String inputName = editController.text.trim().toLowerCase();
              bool isDuplicate = _deptList.any((d) =>
              (d['dept_name']?.toString() ?? '').trim().toLowerCase() == inputName && d['id'] != dept['id']
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("This department name already exists."), backgroundColor: Colors.redAccent),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool success = await _controller.updateDepartment(dept['id'], editController.text.trim(), widget.token);
              _loadData();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Department updated successfully.' : 'Failed to save modifications.'),
                    backgroundColor: success ? Colors.green : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}