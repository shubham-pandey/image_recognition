import 'dart:io';
import 'package:flutter/material.dart';
import 'package:final_task/widgets/app_background.dart';
import 'package:image_picker/image_picker.dart';

class CropComingSoonScreen extends StatefulWidget {
  const CropComingSoonScreen({super.key});

  @override
  State<CropComingSoonScreen> createState() => _CropComingSoonScreenState();
}

class _CropComingSoonScreenState extends State<CropComingSoonScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crop', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5),
  iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: Center(
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _imageFile == null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.image_outlined, size: 96, color: Colors.white70),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.upload_file), label: const Text('Upload Image')),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))]),
                    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.contain)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Crop will be available soon!', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.upload_file), label: const Text('Change Image')),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }
}
