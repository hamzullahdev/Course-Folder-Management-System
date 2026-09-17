import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/AdminController/FolderController.dart';

class FolderScreen extends StatefulWidget {
  final String? token;
  const FolderScreen({super.key, this.token});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final FolderController controller = Get.put(FolderController());
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      controller.initializeData(widget.token!);
    }
  }

  Future<void> _onRefresh() async {
    controller.folderNameController.clear();
    controller.noOfFilesController.clear();
    await controller.fetchFolders();
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Folder Name Field
                              TextFormField(
                                controller: controller.folderNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Folder Name",
                                  hintText: "e.g., a-Course Objectives",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.folder, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Folder name is required.' : null,
                              ),
                              const SizedBox(height: 14),

                              // 2. No of Files Field
                              TextFormField(
                                controller: controller.noOfFilesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "No of Files",
                                  hintText: "e.g., 0",
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.file_copy, color: Colors.white70),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 3. CREATE FOLDER Button
                              Obx(() => SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F51B5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 5,
                                  ),
                                  onPressed: controller.isAdding.value ? null : () {
                                    if (_formKey.currentState!.validate()) {
                                      controller.addFolder();
                                    }
                                  },
                                  child: controller.isAdding.value
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text(
                                      "CREATE FOLDER",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ================= MULTI-DIRECTIONAL CUSTOM SCROLL DATA GRID =================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double computedWidth = max(constraints.maxWidth, 600);

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: computedWidth,
                          child: Column(
                            children: [
                              // Grid Row Header Layout Structure
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E).withOpacity(0.9),
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text("Folder Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                    Expanded(flex: 2, child: Text("No of Files", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                    SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                    SizedBox(width: 100, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),

                              // Grid Reactive Body Content Framework
                              Container(
                                height: 450,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                ),
                                child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                                  }

                                  if (controller.allFolders.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No folders exist in the database.",
                                        style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: controller.allFolders.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                    itemBuilder: (ctx, i) {
                                      var folder = controller.allFolders[i];

                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.folder, color: Colors.amber, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(folder['folder_name']?.toString() ?? 'Unnamed', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  ],
                                                )
                                            ),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                            Expanded(
                                                flex: 2,
                                                child: Text(folder['no_of_files']?.toString() ?? '0', style: const TextStyle(color: Colors.black87, fontSize: 14), textAlign: TextAlign.center, maxLines: 1)
                                            ),
                                            const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                                    onPressed: () => _showEditDialog(ctx, folder),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                                    onPressed: () => _confirmDelete(ctx, folder),
                                                  ),
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

  // ================= MUTATION MANAGEMENT MODAL ENGINE =================
  void _showEditDialog(BuildContext ctx, dynamic folder) {
    final TextEditingController editNameController = TextEditingController(text: folder['folder_name']?.toString() ?? '');
    final TextEditingController editFilesController = TextEditingController(text: folder['no_of_files']?.toString() ?? '0');

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: const Text(
            "Modify Folder Directory",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Folder Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: editFilesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "No of Files",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Map<String, dynamic> body = {
                  "folder_name": editNameController.text.trim(),
                  "no_of_files": int.tryParse(editFilesController.text.trim()) ?? 0,
                };
                controller.updateFolder(folder['folder_id'], body);
                Navigator.pop(context);
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // ================= DELETE CONFIRMATION ENGINE =================
  void _confirmDelete(BuildContext ctx, dynamic folder) {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: const Text("Confirm Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete the folder '${folder['folder_name']}'? This action cannot be undone.", style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                controller.deleteFolder(folder['folder_id']);
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