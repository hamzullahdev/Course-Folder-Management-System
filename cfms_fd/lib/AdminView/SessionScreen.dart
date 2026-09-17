import 'dart:ui';
import 'package:flutter/material.dart';
import '../ViewModel/Controller/AdminController/SessionController.dart';

class SessionScreen extends StatefulWidget {
  final String token;
  const SessionScreen({super.key, required this.token});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final SessionController _sessionController = SessionController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _sessionController.fetchSessions(widget.token);

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _sessions = result['data'] ?? [];
        } else {
          _showToast(result['message'] ?? 'Error fetching sessions.', Colors.red);
        }
        _isLoading = false;
      });
    }
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // Helper method to parse DD/MM/YYYY into DateTime for checking active state
  DateTime? _parseDisplayDate(String dateStr) {
    try {
      final cleanStr = dateStr.split(' ')[0]; // removes any unexpected timestamps
      final parts = cleanStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  // Verifies if the session is currently operational/active
  bool _isSessionActive(String startStr, String endStr) {
    final startDate = _parseDisplayDate(startStr);
    final endDate = _parseDisplayDate(endStr);
    if (startDate == null || endDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Returns true if today falls exactly between or on the dates
    return !today.isBefore(startDate) && !today.isAfter(endDate);
  }

  // Standard DatePicker rendering formatted layout string directly
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3F51B5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String day = picked.day.toString().padLeft(2, '0');
      String month = picked.month.toString().padLeft(2, '0');
      String year = picked.year.toString();
      controller.text = "$day/$month/$year"; // Saved cleanly as DD/MM/YYYY
    }
  }

  // Dialog window for recording modifications
  void _showEditDialog(Map<String, dynamic> session) {
    final _editFormKey = GlobalKey<FormState>();
    final TextEditingController _editNameController = TextEditingController(text: session['s_name']?.toString() ?? '');
    final TextEditingController _editStartController = TextEditingController(text: session['start_date']?.toString() ?? '');
    final TextEditingController _editEndController = TextEditingController(text: session['end_date']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Session Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _editNameController,
                  decoration: const InputDecoration(labelText: 'Session Name', hintText: 'e.g., Fall 2026', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _editStartController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _editStartController),
                  decoration: const InputDecoration(labelText: 'Start Date (DD/MM/YYYY)', suffixIcon: Icon(Icons.calendar_month), border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _editEndController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _editEndController),
                  decoration: const InputDecoration(labelText: 'End Date (DD/MM/YYYY)', suffixIcon: Icon(Icons.calendar_month), border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
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
                  // Duplicate Check for Edit Panel (Excludes current row ID)
                  final inputName = _editNameController.text.trim().toLowerCase();
                  final currentId = session['id'].toString();
                  bool isDuplicate = _sessions.any((s) =>
                  (s['s_name'] ?? '').toString().trim().toLowerCase() == inputName &&
                      s['id'].toString() != currentId);

                  if (isDuplicate) {
                    _showToast("A session with this name already exists.", Colors.red);
                    return;
                  }

                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  final result = await _sessionController.updateSession(
                    widget.token,
                    int.tryParse(session['id'].toString()) ?? 0,
                    _editNameController.text.trim(),
                    _editStartController.text,
                    _editEndController.text,
                  );

                  if (result['success'] == true) {
                    _showToast('Session updated successfully!', Colors.green);
                  } else {
                    _showToast(result['message'] ?? 'Update failed.', Colors.red);
                  }
                  await _loadData();
                }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
              onRefresh: _loadData,
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
                              TextFormField(
                                controller: _sNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Session Name",
                                  hintText: "e.g., Fall 2026",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.bookmark, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Session name is required.' : null,
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _startDateController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context, _startDateController),
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: "Start Date",
                                        hintText: "DD/MM/YYYY",
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        hintStyle: const TextStyle(color: Colors.white38),
                                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _endDateController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context, _endDateController),
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: "End Date",
                                        hintText: "DD/MM/YYYY",
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        hintStyle: const TextStyle(color: Colors.white38),
                                        prefixIcon: const Icon(Icons.event, color: Colors.white70, size: 20),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ],
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
                                    if (!_formKey.currentState!.validate()) return;

                                    // Duplicate Check for Form Field Creation
                                    final inputName = _sNameController.text.trim().toLowerCase();
                                    bool isDuplicate = _sessions.any((s) => (s['s_name'] ?? '').toString().trim().toLowerCase() == inputName);

                                    if (isDuplicate) {
                                      _showToast("A session with this name already exists.", Colors.red);
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    final result = await _sessionController.createSession(
                                      widget.token,
                                      _sNameController.text.trim(),
                                      _startDateController.text, // Direct DD/MM/YYYY string
                                      _endDateController.text,   // Direct DD/MM/YYYY string
                                    );

                                    if (result['success'] == true) {
                                      _showToast("Session created successfully!", Colors.green);
                                      _sNameController.clear();
                                      _startDateController.clear();
                                      _endDateController.clear();
                                      await _loadData();
                                    } else {
                                      _showToast(result['message'] ?? "Failed to create session.", Colors.red);
                                      setState(() => _isLoading = false);
                                    }
                                  },
                                  child: const Text("ADD SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- DATA GRID HEADERS ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.9),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text("Session Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Start Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text("End Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 70, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),

                  // --- DATA GRID ITEMS ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    child: _sessions.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No sessions found.", style: TextStyle(color: Colors.grey))))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (_, i) {
                        var session = _sessions[i];
                        String name = (session['s_name'] ?? 'N/A').toString();
                        String sDate = (session['start_date'] ?? '').toString();
                        String eDate = (session['end_date'] ?? '').toString();

                        // Active flag calculations run smoothly on execution
                        bool active = _isSessionActive(sDate, eDate);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          child: Row(
                            children: [
                              // Session Name Block + Active Badge check
                              Expanded(
                                flex: 3,
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (active)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green, width: 0.8)
                                        ),
                                        child: const Text(
                                          "Active",
                                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Start Date Column alignment
                              Expanded(
                                flex: 2,
                                child: Text(sDate, style: const TextStyle(fontSize: 13, color: Colors.black87), textAlign: TextAlign.center),
                              ),
                              // End Date Column alignment
                              Expanded(
                                flex: 2,
                                child: Text(eDate, style: const TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
                              ),
                              // Action Column buttons
                              SizedBox(
                                width: 70,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.edit, color: Colors.indigo, size: 18),
                                      onPressed: () => _showEditDialog(session),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                      onPressed: () async {
                                        setState(() => _isLoading = true);
                                        final sId = int.tryParse(session['id'].toString()) ?? 0;
                                        final result = await _sessionController.deleteSession(widget.token, sId);
                                        await _loadData();

                                        if (mounted) {
                                          _showToast(
                                              result['success'] == true ? 'Deleted successfully.' : 'Delete failed.',
                                              result['success'] == true ? Colors.green : Colors.redAccent
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