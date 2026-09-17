import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../ViewModel/Controller/AdminController/ReportChecklistController.dart';

class ReportChecklistScreen extends StatefulWidget {
  final String token;
  final String allocationId;
  final String courseName;

  const ReportChecklistScreen({
    super.key,
    required this.token,
    required this.allocationId,
    required this.courseName,
  });

  @override
  State<ReportChecklistScreen> createState() => _ReportChecklistScreenState();
}

class _ReportChecklistScreenState extends State<ReportChecklistScreen> {
  late ReportChecklistController controller;

  @override
  void initState() {
    super.initState();
    // Unique tag lagaya hai taake purana data mix na ho
    controller = Get.put(ReportChecklistController(token: widget.token), tag: widget.allocationId);
    controller.fetchChecklist(widget.allocationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                // --- TOP HEADER ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                            "Checklist: ${widget.courseName}",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ],
                  ),
                ),

                // --- DATA GRID HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 4, child: Text("File Requirement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text("Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),

                // --- DATA GRID BODY ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                      ),
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                        }
                        if (controller.checklist.isEmpty) {
                          return const Center(child: Text("No file requirements configured.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)));
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: controller.checklist.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                          itemBuilder: (_, i) {
                            var item = controller.checklist[i];
                            bool isComplete = item['status'] == 'Complete';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                      flex: 4,
                                      child: Text(item['file_name'] ?? 'Unknown File', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)))
                                  ),
                                  Expanded(
                                      flex: 3,
                                      child: Text(
                                          item['status'] ?? 'Incomplete',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isComplete ? Colors.green : Colors.redAccent
                                          )
                                      )
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: isComplete
                                          ? IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.visibility, color: Color(0xFF3F51B5), size: 24),
                                        onPressed: () => controller.viewFile(item['file_path'] ?? ''),
                                      )
                                          : const SizedBox(height: 24),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}