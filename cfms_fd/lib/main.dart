import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 1. Yeh import lazmi add karein
import 'View/LoginView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. MaterialApp ko GetMaterialApp se replace karein
    return GetMaterialApp(
      title: 'Course Folder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const LoginView(),
    );
  }
}