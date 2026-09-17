import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../ViewModel/Controller/AdminController/CoursesController.dart';

class CoursesScreen extends StatefulWidget {
  final String token;
  const CoursesScreen({super.key, required this.token});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CoursesController _controller = CoursesController();

  final GlobalKey<FormFieldState> _deptDropdownKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _progDropdownKey = GlobalKey<FormFieldState>();

  List<dynamic> _allCourses = [];
  List<dynamic> _filteredCourses = [];
  List<dynamic> _deptList = [];
  List<dynamic> _allPrograms = [];
  List<dynamic> _filteredPrograms = [];

  int? _selectedDeptId;
  int? _selectedProgId;
  bool _isLoading = true;
  String? _pickedFilePath;
  String _displayFileName = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Method to reload data from API (used for initialization & pull-to-refresh)
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var courses = await _controller.fetchCourses(widget.token);
    var depts = await _controller.fetchDepartments(widget.token);
    var progs = await _controller.fetchPrograms(widget.token);

    if (!mounted) return;
    setState(() {
      _allCourses = courses;
      _deptList = depts;
      _allPrograms = progs;
      _applyFilters();
      _isLoading = false;
    });
  }

  // Reset dropdown filters and reload everything to default configuration
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
      // 1. Filter Program Dropdown context based on Department Selection
      if (_selectedDeptId != null) {
        _filteredPrograms = _allPrograms.where((p) {
          final dId = int.tryParse(p['department_id']?.toString() ?? '');
          return dId == _selectedDeptId;
        }).toList();
      } else {
        _filteredPrograms = List.from(_allPrograms);
      }

      // 2. Data Table Grid Filtering
      _filteredCourses = _allCourses.where((course) {
        bool matchesDept = true;
        bool matchesProg = true;

        if (_selectedDeptId != null) {
          var deptIdFromCourse = course['program']?['department_id'] ?? course['department_id'];
          final parsedDeptId = int.tryParse(deptIdFromCourse?.toString() ?? '');
          matchesDept = (parsedDeptId == _selectedDeptId);
        }
        if (_selectedProgId != null) {
          final parsedProgId = int.tryParse(course['program_id']?.toString() ?? '');
          matchesProg = (parsedProgId == _selectedProgId);
        }

        return matchesDept && matchesProg;
      }).toList();
    });
  }

  void _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (!mounted) return;

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;
        String extension = fileName.split('.').last.toLowerCase();

        if (extension == 'xlsx' || extension == 'xls') {
          setState(() {
            _pickedFilePath = filePath;
            _displayFileName = fileName;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Excel file selected: $_displayFileName"),
                backgroundColor: Colors.indigo
            ),
          );
        } else {
          setState(() {
            _pickedFilePath = null;
            _displayFileName = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: Please select a valid Excel file (.xlsx or .xls) only!"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print("FILE PICKER ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Picker Error: $e"),
            backgroundColor: Colors.redAccent
        ),
      );
    }
  }

  void _showExcelErrorsDialog(List<dynamic> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Excel Validation Errors", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final err = errors[index];
              final rowNum = err['row'] ?? 'Unknown';
              final dynamic column = err['attribute'] ?? '';
              final List<dynamic> msgList = err['errors'] ?? [];
              final fullMsg = msgList.join(", ");

              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  title: Text("Row $rowNum | Column: $column", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                  subtitle: Text(fullMsg, style: const TextStyle(color: Colors.black87)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
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
              color: const Color(0xFF1A237E),
              backgroundColor: Colors.white,
              onRefresh: _handleRefresh, // Pull to refresh execution rule
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Forces scrolling even if content fits to allow pull-to-refresh
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "File Path:",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white38),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _displayFileName.isEmpty ? "No file selected" : _displayFileName,
                                          style: TextStyle(
                                            color: _displayFileName.isEmpty ? Colors.white60 : Colors.white,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3F51B5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: _pickExcelFile,
                                        icon: const Icon(Icons.folder_open, color: Colors.white, size: 20),
                                        label: const Text("Browse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          fixedSize: const Size.fromHeight(42),
                                        ),
                                        onPressed: () async {
                                          if (_pickedFilePath == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text("Please select an Excel file first."),
                                                  backgroundColor: Colors.orange
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => _isLoading = true);
                                          var result = await _controller.uploadExcel(_pickedFilePath!, widget.token);

                                          if (!mounted) return;
                                          setState(() {
                                            _pickedFilePath = null;
                                            _displayFileName = '';
                                          });
                                          _loadAllData();

                                          if (result['success'] == true) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content: Text(result['message'] ?? "Excel imported successfully."),
                                                  backgroundColor: Colors.green
                                              ),
                                            );
                                          } else {
                                            if (result['errors'] != null && result['errors'] is List) {
                                              _showExcelErrorsDialog(result['errors']);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                    content: Text(result['message'] ?? "Failed to import Excel data."),
                                                    backgroundColor: Colors.redAccent
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.file_upload, color: Colors.white, size: 20),
                                        label: const Text("Import", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        key: _deptDropdownKey,
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        hint: const Text("Select Department", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Department",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: _deptList.map((dynamic d) {
                                          final id = int.tryParse(d['id']?.toString() ?? '');
                                          return DropdownMenuItem<int>(
                                            value: id,
                                            child: Text(
                                              d['dept_name']?.toString() ?? d['name']?.toString() ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        key: _progDropdownKey,
                                        isDense: true,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF2A5298),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        hint: const Text("Select Program", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                                        decoration: InputDecoration(
                                          labelText: "Program",
                                          labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white54)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                                        ),
                                        items: _filteredPrograms.map((dynamic p) {
                                          final id = int.tryParse(p['id']?.toString() ?? '');
                                          return DropdownMenuItem<int>(
                                            value: id,
                                            child: Text(
                                              p['program_name']?.toString() ?? p['name']?.toString() ?? '',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() => _selectedProgId = val);
                                          _applyFilters();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
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
                            Expanded(flex: 3, child: Text("Course Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            Expanded(flex: 2, child: Text("Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            Expanded(flex: 2, child: Text("Short Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            Expanded(flex: 2, child: Text("Credit_Hrs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                            SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 10)),
                            // FIXED: Allocated safe specific static space for the Action Column Title
                            SizedBox(width: 90, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      Container(
                        height: 380,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                            : _filteredCourses.isEmpty
                            ? const Center(child: Text("No courses match selection criteria.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)))
                            : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredCourses.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                // ✨ FIXED: Added ?.toString() to safely map any numeric values returned by API
                                Expanded(flex: 3, child: Text(_filteredCourses[i]['course_name']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                Expanded(flex: 2, child: Text(_filteredCourses[i]['course_code']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                Expanded(flex: 2, child: Text(_filteredCourses[i]['short_name']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center)),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                Expanded(flex: 2, child: Text(_filteredCourses[i]['credit_hrs']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), textAlign: TextAlign.center)),
                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 10)),
                                // FIXED: Swapped TextButtons out for compact IconButton objects inside a restricted spatial constraints scope
                                SizedBox(
                                  width: 90,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                        onPressed: () => _editCourseDialog(_filteredCourses[i]),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          var res = await _controller.deleteCourse(_filteredCourses[i]['id'], widget.token);
                                          _loadAllData();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message'] ?? 'Action completed.'),
                                                backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
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

  void _editCourseDialog(dynamic course) {
    TextEditingController editNameController = TextEditingController(text: course['course_name']?.toString());
    TextEditingController editCodeController = TextEditingController(text: course['course_code']?.toString());
    TextEditingController editShortController = TextEditingController(text: course['short_name']?.toString());
    TextEditingController editCreditController = TextEditingController(text: course['credit_hrs']?.toString());

    int? editProgId;
    if (course['program_id'] != null) {
      final targetId = int.tryParse(course['program_id'].toString());
      if (_allPrograms.any((p) => int.tryParse(p['id']?.toString() ?? '') == targetId)) {
        editProgId = targetId;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Modify Course Entry", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: editProgId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Target Program Scope", border: OutlineInputBorder()),
                items: _allPrograms.map((dynamic p) {
                  final pId = int.tryParse(p['id']?.toString() ?? '');
                  return DropdownMenuItem<int>(
                      value: pId,
                      child: Text(
                        p['program_name']?.toString() ?? p['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      )
                  );
                }).toList(),
                onChanged: (val) => editProgId = val,
              ),
              const SizedBox(height: 12),
              TextField(controller: editCodeController, decoration: const InputDecoration(labelText: "Course Code", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: editShortController, decoration: const InputDecoration(labelText: "Short Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: editNameController, decoration: const InputDecoration(labelText: "Course Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: editCreditController, decoration: const InputDecoration(labelText: "Credit Hours", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
            onPressed: () async {
              if (editProgId != null) {
                setState(() => _isLoading = true);
                var res = await _controller.updateCourse(
                    course['id'] is int ? course['id'] : int.parse(course['id'].toString()),
                    editNameController.text.trim(),
                    editCodeController.text.trim(),
                    editShortController.text.trim(),
                    editCreditController.text.trim(),
                    editProgId!,
                    widget.token
                );

                if (res['success'] == true) {
                  if (context.mounted) Navigator.pop(context);
                  _loadAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? "Course updated successfully."), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                  String errorText = res['message'] ?? "Validation Error occurred.";
                  if (res['errors'] != null && res['errors'] is Map) {
                    var mapErrors = res['errors'] as Map<String, dynamic>;
                    errorText = mapErrors.values.map((e) => (e as List).join(", ")).join("\n");
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorText), backgroundColor: Colors.redAccent),
                    );
                  }
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