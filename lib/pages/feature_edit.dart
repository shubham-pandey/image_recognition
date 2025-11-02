import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_processing_service.dart' as img_service;

class FeatureEditScreen extends StatefulWidget {
  final String featureName;

  const FeatureEditScreen({super.key, required this.featureName});

  @override
  State<FeatureEditScreen> createState() => _FeatureEditScreenState();
}

class _FeatureEditScreenState extends State<FeatureEditScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  Future<void> _applyFeature() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      late Map<String, dynamic> result;

      switch (widget.featureName) {
        case 'Find Objects':
          result = await img_service.ImageProcessingService.detectObjects(_imageFile!);
          if (result['success']) {
            _showDetectionsDialog(result['detections'], result['objectTypes']);
          }
          break;

        case 'Text Extractor':
          result = await img_service.ImageProcessingService.extractText(_imageFile!);
          if (result['success']) {
            _showTextDialog(result['extractedText']);
          }
          break;

        case 'Remove Background':
          result = await img_service.ImageProcessingService.removeBackground(_imageFile!);
          if (result['success']) {
            _showProcessedImageDialog(result['outputUrl']);
          }
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
      }

      if (!mounted) return;

      if (result.containsKey('success') && !result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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
                  children: objectTypes.map((type) {
                    return Chip(label: Text(type.toString()));
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Detections:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...detections.map((detection) {
                final conf = (detection['confidence'] * 100).toStringAsFixed(1);
                return Text(
                  '• ${detection['class']}: $conf%',
                  style: const TextStyle(fontSize: 14),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(String extractedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extracted Text'),
        content: SingleChildScrollView(
          child: SelectableText(
            extractedText.isEmpty ? 'No text found in image' : extractedText,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProcessedImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processed Image - Remove Background'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Image processed and ready to download!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _downloadImage(imageUrl),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
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
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(result['data']);
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final downloadedFiles = prefs.getStringList('downloadedFiles') ?? [];
        downloadedFiles.add(fileName);
        await prefs.setStringList('downloadedFiles', downloadedFiles);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to Downloads: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.featureName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Main gradient background (same as HomeScreen)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                  Color(0xFF1a0033),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative circles - top left
          Positioned(
            top: -80,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Decorative circles - bottom right
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _imageFile == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_outlined, size: 96, color: Colors.white70),
                      const SizedBox(height: 24),
                      Text(
                        'Upload an image to edit',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.contain,
                            height: 300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Change Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _applyFeature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isProcessing ? Colors.grey : const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Apply edit',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ],
                  )
                  
            ),
          ),
        ],
      ),
    );
  }
}