import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_processing_service.dart' as img_service;

class EditPage extends StatefulWidget {
  final File imageFile;

  const EditPage({super.key, required this.imageFile});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  int _selectedFeature = 0;
  bool _isProcessing = false;

  final List<String> features = [
    'Find Objects',
    'Text Extractor',
    'Remove Background',
    'Image Converter',
    'Brightness',
    'Crop',
  ];

  final List<IconData> featureIcons = [
    Icons.search,
    Icons.text_fields,
    Icons.brush,
    Icons.transform,
    Icons.brightness_6,
    Icons.crop,
  ];

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() {
    _imageFile = null;
  });

  Future<void> _applyFeature() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      late Map<String, dynamic> result;

      switch (_selectedFeature) {
        case 0: // Find Objects
          result = await img_service.ImageProcessingService.detectObjects(_imageFile!);
          if (result['success']) {
            _showDetectionsDialog(result['detections'], result['objectTypes']);
          }
          break;

        case 1: // Text Extractor
          result = await img_service.ImageProcessingService.extractText(_imageFile!);
          if (result['success']) {
            _showTextDialog(result['extractedText']);
          }
          break;

        case 2: // Remove Background
          result = await img_service.ImageProcessingService.removeBackground(_imageFile!);
          if (result['success']) {
            _showProcessedImageDialog(result['outputUrl']);
          }
          break;

        case 3: // Image Converter
          _showComingSoonSnackbar('Image Converter');
          break;

        case 4: // Brightness
          _showComingSoonSnackbar('Brightness Adjustment');
          break;

        case 5: // Crop
          _showComingSoonSnackbar('Image Crop');
          break;
      }

      if (!mounted) return;

      if (!result['success']) {
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

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final result = await img_service.ImageProcessingService.downloadImage(imageUrl);
      
      if (!mounted) return;

      if (result['success']) {
        // Create file with timestamp
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
        Navigator.pop(context); // Close dialog after download
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Edit Photo - ${features[_selectedFeature]}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.2),
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
          // Background gradient (same as HomeScreen)
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
          // Decorative circles
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
          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isProcessing
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  'Processing with ${features[_selectedFeature]}...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : _imageFile == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.image_outlined, size: 96, color: Colors.white70),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'No image selected',
                                      style: TextStyle(
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
                                          label: const Text('Change'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
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
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  features.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFeature = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFeature == index
                              ? const Color(0xFF6C63FF)
                              : Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFeature == index
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              featureIcons[index],
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              features[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _imageFile != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _applyFeature,
              backgroundColor: _isProcessing ? Colors.grey : const Color(0xFF6C63FF),
              label: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Apply Feature',
                      style: TextStyle(color: Colors.white),
                    ),
              icon: !_isProcessing ? const Icon(Icons.check, color: Colors.white) : null,
            )
          : null,
    );
  }
}