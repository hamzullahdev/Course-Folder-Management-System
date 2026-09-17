import 'package:cfms_fd/TeacherView/ChangePasswordScreen.dart';
import 'package:cfms_fd/TeacherView/ChecklistScreen.dart';
import 'package:cfms_fd/TeacherView/ClosPlosMappingScreen.dart';
import 'package:cfms_fd/TeacherView/FcarScreen.dart';
import 'package:cfms_fd/TeacherView/QuestionScreen.dart';
import 'package:cfms_fd/TeacherView/ResultScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../View/LoginView.dart';
import '../ViewModel/Controller/authController/AuthController.dart';
import 'MyCoursesScreen.dart';
import 'AssessmentScreen.dart';
import 'ViewClosScreen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final String token;
  final String email;

  const TeacherHomeScreen({super.key, required this.token, required this.email});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthController _authController = AuthController();

  // Balanced Deep Royal Navy Blue Palette (Matched with Admin)
  final Color primaryDark = const Color(0xFF1E3C72);
  final Color primaryLight = const Color(0xFF2A5298);

  String _selectedPage = "My Courses";

  // Teacher Menu Items (Managing Content is completely removed)
  final List<Map<String, dynamic>> _menuItems = [
    {"title": "My Courses", "icon": Icons.menu_book_outlined},
    {"title": "Assessments", "icon": Icons.assessment_outlined},
    {"title": "Questions", "icon": Icons.help_outline},
    {"title": "Results", "icon": Icons.bar_chart_outlined},
    {"title": "View CLOs", "icon": Icons.visibility_outlined},
    {"title": "CLOs PLOs Mapping", "icon": Icons.account_tree_outlined},
    {"title": "Checklist", "icon": Icons.checklist_rtl_outlined},
    {"title": "Generate FCAR", "icon": Icons.document_scanner_outlined},
    {"title": "Change Password", "icon": Icons.lock_outline},
  ];

  // Admin Screen ki tarah Cases lagaye gaye hain
  Widget _buildPage() {
    switch (_selectedPage) {
      case "My Courses":return MyCoursesScreen(token: widget.token);

    // Future screens ke liye cases ready hain (Currently showing under construction)
      case "Assessments":return AssessmentScreen(token: widget.token);
      case "Questions":return QuestionScreen(token: widget.token);
      case "Results":return ResultScreen(token: widget.token);
      case "View CLOs":return ViewClosScreen(token: widget.token);
      case "CLOs PLOs Mapping":return ClosPlosMappingScreen(token: widget.token);
      case "Checklist":return ChecklistScreen(token: widget.token);
      case "Generate FCAR":return FcarScreen(token: widget.token);
      case "Change Password":return ChangePasswordScreen(token: widget.token);
      default:
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Center(
            child: Text(
              "Page: $_selectedPage\nis not created 🚀",
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
      appBar: AppBar(
        title: Text(
            _selectedPage,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.8, fontSize: 20)
        ),
        elevation: 0,
        backgroundColor: primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          SizedBox(width: 8)
        ],
      ),
      drawer: Drawer(
        elevation: 16,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Premium Profile Header Design matched with Admin
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
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                ),
                accountName: const Text(
                    "Teacher",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)
                ),
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