import 'dart:convert';
import 'dart:ui'; // ✨ FIX: Glassmorphism Blur ke liye lazmi hai
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../View/LoginView.dart';
import '../ViewModel/Controller/authController/AuthController.dart';

class StudentHomeScreen extends StatefulWidget {
  final String token;
  final String email;

  const StudentHomeScreen({super.key, required this.token, required this.email});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthController _authController = AuthController();

  // Premium Space Glassmorphic Theme Colors
  final Color bgDark = const Color(0xFF0F2027);
  final Color bgMid = const Color(0xFF203A43);
  final Color bgLight = const Color(0xFF2C5364);

  bool isLoading = true;
  String studentName = "";
  String regNo = "";

  List<dynamic> allResults = [];
  List<dynamic> filteredResults = [];
  List<dynamic> enrolledCourses = [];

  String selectedCourseId = "All";

  @override
  void initState() {
    super.initState();
    fetchMyDashboardData();
  }

  Future<void> fetchMyDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/my-results'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          studentName = data['student_name'] ?? 'Student';
          regNo = data['reg_no'] ?? '';
          enrolledCourses = data['enrolled_courses'] ?? [];
          allResults = data['results'] ?? [];
          filteredResults = List.from(allResults);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        try {
          var errorData = jsonDecode(response.body);
          Get.snackbar("API Error", errorData['message'] ?? "Failed to fetch.", backgroundColor: Colors.redAccent, colorText: Colors.white);
        } catch (e) {
          Get.snackbar("Server Error", "Code: ${response.statusCode}", backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Network Error", "Connection failed", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void filterResults(String courseId) {
    setState(() {
      selectedCourseId = courseId;
      if (courseId == "All") {
        filteredResults = List.from(allResults);
      } else {
        filteredResults = allResults.where((r) => r['course_id'].toString() == courseId).toList();
      }
    });
  }

  String calculateSemester(String batchName, String sessionName) {
    try {
      if (batchName == 'N/A' || sessionName == 'N/A') return 'N/A';
      RegExp yearRegExp = RegExp(r'\d{4}');
      var batchMatch = yearRegExp.firstMatch(batchName);
      var sessionMatch = yearRegExp.firstMatch(sessionName);

      if (batchMatch != null) {
        int admissionYear = int.parse(batchMatch.group(0)!);
        int sessionYear = sessionMatch != null ? int.parse(sessionMatch.group(0)!) : DateTime.now().year;

        int yearDiff = sessionYear - admissionYear;
        int semester = 1;

        String sLower = sessionName.toLowerCase();
        String bLower = batchName.toLowerCase();

        if (sLower.contains('fall')) {
          semester = (yearDiff * 2) + 1;
        } else if (sLower.contains('spring')) {
          semester = (yearDiff * 2);
        } else if (sLower.contains('summer')) {
          semester = (yearDiff * 2);
        } else {
          semester = (yearDiff * 2) + 1;
        }

        if (bLower.contains('spring')) semester += 1;
        if (semester < 1) semester = 1;

        String suffix = "th";
        if (semester % 10 == 1 && semester % 100 != 11) suffix = "st";
        else if (semester % 10 == 2 && semester % 100 != 12) suffix = "nd";
        else if (semester % 10 == 3 && semester % 100 != 13) suffix = "rd";

        if (sLower.contains('summer')) return "$semester$suffix (Sum)";
        return "$semester$suffix";
      }
    } catch (e) {
      debugPrint("Semester Error: $e");
    }
    return "1st";
  }

  // ✨ Glassmorphic Reusable Container Widget
  Widget _buildGlassContainer({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Student Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        elevation: 0,
        backgroundColor: bgDark.withOpacity(0.9),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
              currentAccountPicture: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 2)),
                child: const CircleAvatar(backgroundColor: Colors.transparent, child: Icon(Icons.school, size: 36, color: Colors.white)),
              ),
              accountName: Text(studentName.isNotEmpty ? studentName : "Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              accountEmail: Text(widget.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white),
              title: const Text("Academic Results", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  Get.deleteAll();
                  await _authController.logoutUser(widget.token);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
                },
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Canvas
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgDark, bgMid, bgLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✨ Glass Profile Header
                  _buildGlassContainer(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                          child: const Icon(Icons.person_outline, size: 35, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("Reg No: $regNo", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ✨ Glass Dropdown Filter
                  const Text(" Filter by Subject", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                  const SizedBox(height: 8),
                  _buildGlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: bgMid,
                        value: selectedCourseId,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        items: [
                          const DropdownMenuItem(value: "All", child: Text("All Enrolled Courses")),
                          ...enrolledCourses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course['id'].toString(),
                              child: Text(course['course_name'] ?? 'Unknown Course'),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          if (val != null) filterResults(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text(" Result Transcript", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),

                  // ✨ Glass Table Grid
                  Expanded(
                    child: filteredResults.isEmpty
                        ? _buildGlassContainer(
                      child: const Center(
                        child: Text("No result records found.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    )
                        : _buildGlassContainer(
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.white.withOpacity(0.15)),
                            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
                            dividerThickness: 0.5,
                            columns: const [
                              DataColumn(label: Text("Subject")),
                              DataColumn(label: Text("Batch")),
                              DataColumn(label: Text("Semester")),
                              DataColumn(label: Text("Marks")),
                              DataColumn(label: Text("Grade")),
                            ],
                            rows: filteredResults.map((res) {
                              String currentSemester = calculateSemester(res['batch'], res['session']);
                              return DataRow(
                                  cells: [
                                    DataCell(Text(res['subject'], style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(res['batch'])),
                                    DataCell(Text(currentSemester)),
                                    DataCell(Text("${res['obtained_marks']} / ${res['max_marks']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: (res['grade'] == 'F') ? Colors.redAccent.withOpacity(0.25) : Colors.greenAccent.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: (res['grade'] == 'F') ? Colors.redAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.5))
                                          ),
                                          child: Text(
                                              res['grade'],
                                              style: TextStyle(fontWeight: FontWeight.w900, color: (res['grade'] == 'F') ? Colors.redAccent : Colors.greenAccent)
                                          ),
                                        )
                                    ),
                                  ]
                              );
                            }).toList(),
                          ),
                        ),
                      ),
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
}