import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/AdminController/FilesController.dart';

class FilesScreen extends StatefulWidget {
  final String? token;
  const FilesScreen({super.key, this.token});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final FilesController controller = Get.put(FilesController());

  @override
  void initState() {
    super.initState();
    // Screen load hote hi Controller ko Token assign karna
    if (widget.token != null) {
      controller.initializeData(widget.token!);
    }
  }


  Future<void> _onRefresh() async {
    controller.fileNameController.clear();
    controller.selectedFolderId.value = '';
    await controller.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ================= BACKGROUND DEEP BLUE GRADIENT =================
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
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ================= INPUT FORM PANEL (SessionScreen Design) =================
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Dropdown for Folders
                            Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              dropdownColor: const Color(0xFF2A5298),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              value: controller.selectedFolderId.value.isEmpty ? null : controller.selectedFolderId.value,
                              hint: const Text("Select Destination Folder", style: TextStyle(color: Colors.white38)),
                              decoration: InputDecoration(
                                labelText: "Folder",
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.folder_open, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                              ),
                              items: controller.validFolders.map((folder) {
                                return DropdownMenuItem<String>(
                                  value: folder['folder_id'].toString(),
                                  child: Text(folder['folder_name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  controller.selectedFolderId.value = val;
                                  controller.applyFilter(); // Trigger grid filter instantly
                                }
                              },
                            )),
                            const SizedBox(height: 14),

                            // 2. File Name Input Field
                            TextFormField(
                              controller: controller.fileNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: "File Name",
                                hintText: "e.g., Assignment_1_Best(Sample)",
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintStyle: const TextStyle(color: Colors.white38),
                                prefixIcon: const Icon(Icons.insert_drive_file, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 3. CREATE FILE Button
                            Obx(() => SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F51B5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                                onPressed: controller.isAdding.value ? null : () => controller.addFile(),
                                child: controller.isAdding.value
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text(
                                    "CREATE FILE",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ================= DATA GRID (Original Design) =================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Grid specifically sized for Two Columns
                      final double computedWidth = max(constraints.maxWidth, 500);

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: computedWidth,
                          child: Column(
                            children: [
                              // Grid Row Header
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E).withOpacity(0.9),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text("File Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                    SizedBox(width: 100, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),

                              // Grid Body
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                ),
                                child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                                  }
                                  if (controller.selectedFolderId.value.isEmpty) {
                                    return const Center(child: Text("Select a folder to view its files.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)));
                                  }
                                  if (controller.filteredFiles.isEmpty) {
                                    return const Center(child: Text("No files found in this folder.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)));
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: controller.filteredFiles.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                    itemBuilder: (ctx, i) {
                                      var file = controller.filteredFiles[i];

                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.description, color: Colors.blueAccent, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(file['file_name']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  ],
                                                )
                                            ),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit, color: Colors.indigo, size: 20), onPressed: () => _showEditDialog(ctx, file)),
                                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(ctx, file)),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, dynamic file) {
    final TextEditingController editNameController = TextEditingController(text: file['file_name']?.toString() ?? '');

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: const Text("Modify File Record", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "File Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Map<String, dynamic> body = {
                  "file_name": editNameController.text.trim(),
                };
                controller.updateFile(file['file_id'], body);
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, dynamic file) {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: const Text("Confirm Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Delete '${file['file_name']}' permanently?", style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                controller.deleteFile(file['file_id']);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}