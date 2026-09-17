import 'package:cfms_fd/AdminView/CourseAllocationScreen.dart';
import 'package:cfms_fd/AdminView/CourseOfferedScreen.dart';
import 'package:cfms_fd/AdminView/EnrollmentScreen.dart';
import 'package:cfms_fd/AdminView/FilesScreen.dart';
import 'package:cfms_fd/AdminView/FolderScreen.dart';
import 'package:cfms_fd/AdminView/PlosScreen.dart';
import 'package:cfms_fd/AdminView/ReportScreen.dart';
import 'package:cfms_fd/AdminView/SessionScreen.dart';
import 'package:cfms_fd/AdminView/StudentScreen.dart';
import 'package:cfms_fd/AdminView/SubFolderScreen.dart';
import 'package:cfms_fd/AdminView/TeacherScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../View/LoginView.dart';
import '../ViewModel/Controller/authController/AuthController.dart';
import 'BatchScreen.dart';
import 'CloScreen.dart';
import 'CoursesScreen.dart';
import 'Department.dart';
import 'ProgramScreen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String email; // Only Email Change: Added email parameter to receive database email
  const HomeScreen({super.key, required this.token, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();

  // Balanced Deep Royal Navy Blue Palette
  final Color primaryDark = const Color(0xFF1E3C72);
  final Color primaryLight = const Color(0xFF2A5298);
  final Color accentIndigo = const Color(0xFF1A237E);

  String _selectedPage = "Department";

  final List<Map<String, dynamic>> _menuItems = [
    {"title": "Department", "icon": Icons.business_outlined},
    {"title": "Program", "icon": Icons.school_outlined},
    {"title": "PLOs", "icon": Icons.analytics_outlined},
    {"title": "Courses", "icon": Icons.menu_book_outlined},
    {"title": "CLOs", "icon": Icons.assignment_turned_in_outlined},
    {"title": "Batch", "icon": Icons.schedule_outlined},
    {"title": "Session", "icon": Icons.date_range_outlined},
    {"title": "Students", "icon": Icons.person_outline},
    {"title": "Teachers", "icon": Icons.people_alt_outlined},
    {"title": "Offered Course", "icon": Icons.collections_bookmark_outlined},
    {"title": "Enrollment", "icon": Icons.assignment_ind_outlined},
    {"title": "Course Allocation", "icon": Icons.account_tree_outlined},
    {"title": "Folders", "icon": Icons.folder_outlined},
    {"title": "Subfolder", "icon": Icons.folder_open_outlined},
    {"title": "Files", "icon": Icons.description_outlined},
    {"title": "Report", "icon": Icons.insert_chart_outlined_rounded},
  ];

  Widget _buildPage() {
    switch (_selectedPage) {
      case "Department": return DepartmentScreen(token: widget.token);
      case "Program": return ProgramScreen(token: widget.token);
      case "PLOs": return PLOsScreen(token: widget.token);
      case "Courses": return CoursesScreen(token: widget.token);
      case "CLOs": return CloScreen(token: widget.token);
      case "Batch": return BatchScreen(token: widget.token);
      case "Session":return SessionScreen(token: widget.token);
      case "Students":return StudentScreen(token: widget.token, email: '',);
      case "Teachers":return TeacherScreen(token: widget.token);
      case "Offered Course":return CourseOfferedScreen(token: widget.token);
      case "Enrollment": return EnrollmentScreen(token: widget.token);
      case "Course Allocation": return CourseAllocationScreen(token: widget.token);
      case "Folders": return FolderScreen(token: widget.token);
      case "Subfolder": return SubFolderScreen(token: widget.token);
      case "Files": return FilesScreen(token: widget.token);
      case "Report": return ReportScreen(token: widget.token);
      default:
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Center(
            child: Text(
              "Page: $_selectedPage\nis under construction 🚀",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern clean AppBar mimicking top-tier dashboards
      appBar: AppBar(
        title: Text(
            _selectedPage,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.8, fontSize: 20)
        ),
        elevation: 0,
        backgroundColor: primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        // FIXED: Removed the notification IconButton from actions list
        actions: const [
          SizedBox(width: 8)
        ],
      ),
      drawer: Drawer(
        elevation: 16,
        child: Container(
          // Smooth sidebar gradient
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Premium Profile Header Design
              UserAccountsDrawerHeader(
                margin: EdgeInsets.zero,
                decoration: const BoxDecoration(color: Colors.transparent),
                currentAccountPicture: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 3),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                  ),
                ),
                // Only Changes: Changed "Admin Portal" to "Admin"
                accountName: const Text(
                    "Admin",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)
                ),
                // Only Changes: Displaying dynamic database email here
                accountEmail: Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white60, fontSize: 13)
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              // Menu Items Box
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) => _buildDrawerItem(_menuItems[index]),
                ),
              ),

              // Bottom Static Option (Logout)
              const Divider(color: Colors.white24, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.white),
                      title: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                      ),
                      onTap: () async {
                        Navigator.pop(context); // Close Drawer
                        Get.deleteAll();
                        bool isLoggedOut = await _authController.logoutUser(widget.token);

                        if (mounted) {
                          if (isLoggedOut) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out successfully!'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logout failed on server, forcing local logout.'), backgroundColor: Colors.orange),
                            );
                          }

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                                (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: _buildPage(),
    );
  }

  Widget _buildDrawerItem(Map<String, dynamic> item) {
    bool isSelected = _selectedPage == item['title'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.25), width: 1)
              : null,
          boxShadow: isSelected ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ] : null,
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            item['icon'],
            color: isSelected ? Colors.white : Colors.white60,
            size: 22,
          ),
          title: Text(
              item['title'],
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14.5,
                  letterSpacing: 0.3
              )
          ),
          onTap: () {
            setState(() => _selectedPage = item['title']);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}