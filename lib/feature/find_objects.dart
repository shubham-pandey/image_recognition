import 'dart:io';
import 'package:flutter/material.dart';
import 'package:final_task/widgets/app_background.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_processing_service.dart' as img_service;

class FindObjectsScreen extends StatefulWidget {
  const FindObjectsScreen({super.key});

  @override
  State<FindObjectsScreen> createState() => _FindObjectsScreenState();
}

class _FindObjectsScreenState extends State<FindObjectsScreen> {
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
      final result = await img_service.ImageProcessingService.detectObjects(_imageFile!);
      if (!mounted) return;
      if (result['success']) {
        _showDetectionsDialog(result['detections'], result['objectTypes']);
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

  void _showDetectionsDialog(List<dynamic> detections, List<dynamic> objectTypes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Objects Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (objectTypes.isNotEmpty) ...[
                const Text('Object Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: objectTypes.map((type) => Chip(label: Text(type.toString()))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Detections:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...detections.map((detection) {
                final conf = (detection['confidence'] * 100).toStringAsFixed(1);
                return Text('• ${detection['class']}: $conf%', style: const TextStyle(fontSize: 14));
              }).toList(),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Find Objects', style: TextStyle(color: Colors.white)),
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
