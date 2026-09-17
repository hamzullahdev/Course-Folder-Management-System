import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../ViewModel/Controller/AdminController/SubFolderController.dart';

class SubFolderScreen extends StatefulWidget {
  final String? token;
  const SubFolderScreen({super.key, this.token});

  @override
  State<SubFolderScreen> createState() => _SubFolderScreenState();
}

class _SubFolderScreenState extends State<SubFolderScreen> {
  final SubFolderController controller = Get.put(SubFolderController());

  // ✨ FIX: Yahan initState add kar diya gaya hai!
  @override
  void initState() {
    super.initState();
    // Screen load hote hi Controller ko Token assign karna
    if (widget.token != null) {
      controller.initializeData(widget.token!);
    }
  }

  Future<void> _onRefresh() async {
    controller.subFolderNameController.clear();
    controller.noOfFilesController.clear();
    controller.selectedParentId.value = '';
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Dropdown for Parent Folders
                                Obx(() => DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF2A5298),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  value: controller.selectedParentId.value.isEmpty ? null : controller.selectedParentId.value,
                                  hint: const Text("Select Parent Folder", style: TextStyle(color: Colors.white70)),
                                  decoration: InputDecoration(
                                    labelText: "Parent Folder",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.folder_open, color: Colors.white70, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                                  ),
                                  items: controller.validParents.map((folder) {
                                    return DropdownMenuItem<String>(
                                      value: folder['folder_id'].toString(),
                                      child: Text(folder['folder_name']?.toString() ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) controller.selectedParentId.value = val;
                                  },
                                )),
                                const SizedBox(height: 14),

                                // 2. Sub Folder Name Field
                                _buildGlassTextField(
                                    label: "Sub Folder Name",
                                    hintText: "e.g., Exams",
                                    controller: controller.subFolderNameController,
                                    icon: Icons.create_new_folder
                                ),
                                const SizedBox(height: 14),

                                // 3. No of Files Field
                                _buildGlassTextField(
                                    label: "No of Files",
                                    hintText: "e.g., 0",
                                    controller: controller.noOfFilesController,
                                    icon: Icons.file_copy,
                                    isNumber: true
                                ),
                                const SizedBox(height: 20),

                                // 4. Action Button (CREATE SUB-FOLDER)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: Obx(() => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3F51B5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 5,
                                    ),
                                    onPressed: controller.isAdding.value ? null : () => controller.addSubFolder(),
                                    child: controller.isAdding.value
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text(
                                        "CREATE SUB-FOLDER",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ================= DATA GRID =================
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double computedWidth = max(constraints.maxWidth, 700);

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
                                        Expanded(flex: 2, child: Text("Parent Folder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                        Expanded(flex: 3, child: Text("Sub Folder Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                        Expanded(flex: 1, child: Text("Files", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                        SizedBox(height: 20, child: VerticalDivider(color: Colors.white30, width: 20)),
                                        SizedBox(width: 80, child: Text("Action", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                                      ],
                                    ),
                                  ),

                                  // Grid Reactive Body Content
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
                                      if (controller.allSubFolders.isEmpty) {
                                        return const Center(child: Text("No sub-folders exist.", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)));
                                      }

                                      return ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: controller.allSubFolders.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black26),
                                        itemBuilder: (ctx, i) {
                                          var folder = controller.allSubFolders[i];
                                          var parentName = folder['parent']?['folder_name'] ?? 'Unknown';

                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 2, child: Text(parentName, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                                Expanded(flex: 3, child: Row(
                                                  children: [
                                                    const Icon(Icons.subdirectory_arrow_right, color: Colors.indigo, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(folder['folder_name']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                  ],
                                                )),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                                Expanded(flex: 1, child: Text(folder['no_of_files']?.toString() ?? '0', style: const TextStyle(color: Colors.black87, fontSize: 14), textAlign: TextAlign.center)),
                                                const SizedBox(height: 24, child: VerticalDivider(color: Colors.black12, width: 20)),
                                                SizedBox(
                                                  width: 80,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit, color: Colors.indigo, size: 20), onPressed: () => _showEditDialog(ctx, folder)),
                                                      IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(ctx, folder)),
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
            ),
          ),
        ],
      ),
    );
  }

  // ================= GLASSMORPHIC TEXT FIELD BUILDER =================
  Widget _buildGlassTextField({required String label, required String hintText, required TextEditingController controller, required IconData icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      ),
    );
  }

  // ================= MUTATION MANAGEMENT MODAL ENGINE =================
  void _showEditDialog(BuildContext ctx, dynamic folder) {
    final TextEditingController editNameController = TextEditingController(text: folder['folder_name']?.toString() ?? '');
    final TextEditingController editFilesController = TextEditingController(text: folder['no_of_files']?.toString() ?? '0');
    String currentParentId = folder['parent_id']?.toString() ?? '';

    showDialog(
      context: ctx,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2A5298),
                title: const Text("Modify Sub-Folder", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A5298),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      value: currentParentId.isEmpty ? null : currentParentId,
                      decoration: const InputDecoration(
                        labelText: "Change Parent Folder",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        border: OutlineInputBorder(),
                      ),
                      items: controller.validParents.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['folder_id'].toString(),
                          child: Text(p['folder_name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => currentParentId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Sub Folder Name",
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
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Map<String, dynamic> body = {
                        "folder_name": editNameController.text.trim(),
                        "no_of_files": int.tryParse(editFilesController.text.trim()) ?? 0,
                        "parent_id": int.parse(currentParentId),
                      };
                      controller.updateSubFolder(folder['folder_id'], body);
                      Navigator.pop(context);
                    },
                    child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, dynamic folder) {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A5298),
          title: const Text("Confirm Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Delete '${folder['folder_name']}'? All its contents will be lost.", style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                controller.deleteSubFolder(folder['folder_id']);
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