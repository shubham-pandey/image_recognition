import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_processing_service.dart' as img_service;
import 'package:image/image.dart' as img;

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
  // Brightness/Contrast/Sharpness state
  double _brightness = 0; // -100..100 (0 = neutral)
  double _contrast = 0;   // -100..100 (0 = neutral)
  double _sharpness = 0;  // 0..5
  Uint8List? _previewBytes; // PNG preview for adjustments
  bool _isPreviewProcessing = false;

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
    // If currently in Brightness feature, produce/update preview
    if (_selectedFeature == 4) {
      await _processAdjustments();
    }
  }

  void _removeImage() => setState(() {
    _imageFile = null;
  });

  Future<void> _applyFeature() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      // Default to success so non-server features don't error out
      Map<String, dynamic> result = { 'success': true };

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

        case 3: // Image Converter (coming soon)
          _showComingSoonSnackbar('Image Converter');
          break;

        case 4: // Brightness
          // Handled in the UI with sliders + Save; nothing to call here.
          break;

        case 5: // Crop
          _showComingSoonSnackbar('Image Crop');
          break;
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

  Future<void> _processAdjustments() async {
    if (_imageFile == null) return;
    // Fast path: all neutral -> show original image (no preview bytes)
    if (_brightness.round() == 0 && _contrast.round() == 0 && _sharpness.round() == 0) {
      if (!mounted) return;
      setState(() {
        _previewBytes = null;
        _isPreviewProcessing = false;
      });
      return;
    }
    setState(() => _isPreviewProcessing = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw 'Unsupported image format';
      }

      // Map UI ranges to image package expectations
      final b = (1.0 + (_brightness / 100.0)).clamp(0.0, 2.0); // brightness factor (1.0 = neutral)
      final c = (1.0 + (_contrast / 100.0)).clamp(0.0, 2.0);   // contrast factor (1.0 = neutral)

      // Downscale for responsive preview
      const maxSide = 1024;
      var working = decoded;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        if (decoded.width >= decoded.height) {
          working = img.copyResize(decoded, width: maxSide);
        } else {
          working = img.copyResize(decoded, height: maxSide);
        }
      } else {
        // copy to avoid mutating original
        working = img.copyResize(decoded, width: decoded.width, height: decoded.height);
      }

      working = img.adjustColor(working, brightness: b, contrast: c);

      final sharpInt = _sharpness.round();
      if (sharpInt > 0) {
        const List<num> kernel = [
          0, -1,  0,
         -1,  5, -1,
          0, -1,  0,
        ];
        for (int i = 0; i < sharpInt; i++) {
          working = img.convolution(working, filter: kernel, div: 1, offset: 0);
        }
      }

      final out = Uint8List.fromList(img.encodePng(working));
      if (!mounted) return;
      setState(() => _previewBytes = out);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adjust error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPreviewProcessing = false);
    }
  }

  Future<void> _saveAdjustedImage() async {
    try {
      if (_previewBytes == null) {
        await _processAdjustments();
      }
      if (_previewBytes == null) {
        throw 'No preview to save';
      }

      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(_previewBytes!);

      final prefs = await SharedPreferences.getInstance();
      final downloadedFiles = prefs.getStringList('downloadedFiles') ?? [];
      downloadedFiles.add(fileName);
      await prefs.setStringList('downloadedFiles', downloadedFiles);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to Downloads: $fileName'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save error: $e'), backgroundColor: Colors.red),
      );
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
                              : (_selectedFeature == 4)
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 320,
                                          height: 320,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: const [
                                              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: _isPreviewProcessing
                                                ? const Center(
                                                    child: CircularProgressIndicator(color: Colors.white),
                                                  )
                                                : (_previewBytes != null
                                                    ? Image.memory(_previewBytes!, fit: BoxFit.contain)
                                                    : Image.file(_imageFile!, fit: BoxFit.contain)),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildSlider('Brightness', _brightness, -100, 100, (v) => setState(() => _brightness = v),
                                            onChangeEnd: (_) => _processAdjustments()),
                                        _buildSlider('Contrast', _contrast, -100, 100, (v) => setState(() => _contrast = v),
                                            onChangeEnd: (_) => _processAdjustments()),
                                        _buildSlider('Sharpness', _sharpness, 0, 5, (v) => setState(() => _sharpness = v),
                                            onChangeEnd: (_) => _processAdjustments()),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _pickFromGallery,
                                              icon: const Icon(Icons.upload_file),
                                              label: const Text('Change Image'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white, foregroundColor: Colors.black),
                                            ),
                                            const SizedBox(width: 12),
                                            OutlinedButton.icon(
                                              onPressed: _removeImage,
                                              icon: const Icon(Icons.delete_outline),
                                              label: const Text('Remove'),
                                              style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: (_isPreviewProcessing) ? null : _saveAdjustedImage,
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF6C63FF),
                                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                                          child: const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                      onTap: () async {
                        setState(() => _selectedFeature = index);
                        // If switching to Brightness and image is present, (re)build preview
                        if (index == 4 && _imageFile != null) {
                          await _processAdjustments();
                        }
                      },
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
      floatingActionButton: (_imageFile != null && _selectedFeature != 4)
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

  // Slider builder for adjustments
  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, {ValueChanged<double>? onChangeEnd}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.white))
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}