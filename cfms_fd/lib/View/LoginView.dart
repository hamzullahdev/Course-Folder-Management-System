import 'dart:ui';
import 'package:flutter/material.dart';
import '../AdminView/homescreen.dart';
import '../StudentView/StudentHomeScreen.dart';
import '../TeacherView/TeacherHomescreen.dart';
import '../ViewModel/Controller/authController/AuthController.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _isPasswordHidden = true;

  // Space Cyber Gradient Palette (Matches HomeScreen Theme)
  final Color bgDark = const Color(0xFF0F2027);
  final Color bgMid = const Color(0xFF203A43);
  final Color bgLight = const Color(0xFF2C5364);

  // MUKAMMAL CRASH-PROOF LOGIN LOGIC
  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text
      );

      // DEBUG: Isse VS Code ke console mai pata chalega backend kya bhej raha hai
      print("========== LOGIN DEBUG INFO ==========");
      print("Result from AuthController: $result");
      print("======================================");

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Safe typecasting taake null values par app crash na ho
        String? token = result['token']?.toString();
        String? role = result['role']?.toString();
        String? email = result['email']?.toString();

        // Validation check
        if (token == null || role == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server Error: Token or Role missing in API response!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Role check aur screens par dynamic routing
        if (role.toLowerCase() == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                token: token,
                email: email ?? _emailController.text.trim(), // Fallback email
              ),
            ),
          );
        }
        else if (role.toLowerCase() == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentHomeScreen(
                token: token,
                email: email ?? _emailController.text.trim(),
              ),
            ),
          );
        }
        else {
          // FIXED: Added required email parameter for TeacherHomeScreen here
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherHomeScreen(
                token: token,
                email: email ?? _emailController.text.trim(), // Teacher email passed safely
              ),
            ),
          );
        }
      } else {
        // Agar login credentials ghalat hain ya invalid hain
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login Failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("LOGIN BUTTON CRASH ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Seamless Gradient Canvas
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgDark, bgMid, bgLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Center Layout
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding Icon & Title Context
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.folder_shared_outlined, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "COURSE FOLDER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Text(
                    "Management System",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Glassmorphic Input Form Panel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 35.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 25,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Email / Username Input Field
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white38),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                                validator: (value) => value!.trim().isEmpty ? 'Please enter your email' : null,
                              ),
                              const SizedBox(height: 20),

                              // Password Input Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isPasswordHidden,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() => _isPasswordHidden = !_isPasswordHidden);
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white38),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                                validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                              ),
                              const SizedBox(height: 30),

                              // Premium Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F51B5),
                                    disabledBackgroundColor: const Color(0xFF3F51B5).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    elevation: 6,
                                    shadowColor: const Color(0xFF3F51B5).withOpacity(0.3),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                      : const Text(
                                    "SIGN IN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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