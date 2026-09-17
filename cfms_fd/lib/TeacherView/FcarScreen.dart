import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ViewModel/Controller/TeacherController/FcarController.dart';

class FcarScreen extends StatefulWidget {
  final String token;
  const FcarScreen({super.key, required this.token});

  @override
  State<FcarScreen> createState() => _FcarScreenState();
}

class _FcarScreenState extends State<FcarScreen> {
  late FcarController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FcarController());
    controller.initializeData(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= BACKGROUND GRADIENT =================
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
                // ================= TOP HEADER SELECTION =================
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Faculty Course Assessment", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            Obx(() => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: controller.selectedAllocationId.value.isEmpty ? null : controller.selectedAllocationId.value,
                                  hint: const Text("Select Assigned Course", style: TextStyle(color: Colors.black54)),
                                  items: controller.allocations.map((a) {
                                    return DropdownMenuItem<String>(
                                      value: a['allocation_id'].toString(),
                                      child: Text("${a['course_name']} - ${a['batch_name']} [Sec: ${a['section']}]", style: const TextStyle(fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      controller.selectedAllocationId.value = val;
                                    }
                                  },
                                ),
                              ),
                            )),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Obx(() => ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: controller.selectedAllocationId.value.isEmpty || controller.isGenerating.value
                                    ? null : () => controller.generateReport(),
                                child: controller.isGenerating.value
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : const Text("GENERATE FCAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              )),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Extra Screen UI Hata Di Gayi Hai ---
                const Expanded(
                  child: Center(
                    child: Text(
                      "Select a course to generate and download FCAR.\n Note: The downloaded FCAR will be saved in your phone's Download folder.",
                      textAlign: TextAlign.center, // Yeh text ko center align karega
                      style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5), // height 1.5 se dono lines ke beech thori space aayegi
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}