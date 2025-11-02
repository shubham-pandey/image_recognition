import 'dart:io';
import 'package:flutter/material.dart';
import 'package:final_task/widgets/app_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_processing_service.dart' as img_service;

class RemoveBackgroundScreen extends StatefulWidget {
  const RemoveBackgroundScreen({super.key});

  @override
  State<RemoveBackgroundScreen> createState() => _RemoveBackgroundScreenState();
}

class _RemoveBackgroundScreenState extends State<RemoveBackgroundScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  Future<void> _apply() async {
    if (_imageFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await img_service.ImageProcessingService.removeBackground(_imageFile!);
      if (!mounted) return;
      if (result['success']) {
        _showProcessedImageDialog(result['outputUrl']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showProcessedImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processed Image - Remove Background'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.network(imageUrl, fit: BoxFit.contain, height: 300, errorBuilder: (_, __, ___) => const Text('Failed to load image')),
            const SizedBox(height: 16),
            const Text('Image processed and ready to download!', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(onPressed: () => _downloadImage(imageUrl), icon: const Icon(Icons.download), label: const Text('Download')),
        ],
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final result = await img_service.ImageProcessingService.downloadImage(imageUrl);
      if (!mounted) return;
      if (result['success']) {
        final fileName = 'processed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(result['data']);
        final prefs = await SharedPreferences.getInstance();
        final downloadedFiles = prefs.getStringList('downloadedFiles') ?? [];
        downloadedFiles.add(fileName);
        await prefs.setStringList('downloadedFiles', downloadedFiles);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $fileName'), backgroundColor: Colors.green));
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ${result['error']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Remove Background', style: TextStyle(color: Colors.white)),
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
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.contain, height: 300)),
                  const SizedBox(height: 16),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.upload_file), label: const Text('Change')),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _isProcessing ? null : _apply, child: _isProcessing ? const CircularProgressIndicator() : const Text('Apply')),
                ]),
          ),
        ),
      ),
    );
  }
}
