import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:final_task/widgets/app_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrightnessSharpnessScreen extends StatefulWidget {
  const BrightnessSharpnessScreen({super.key});

  @override
  State<BrightnessSharpnessScreen> createState() => _BrightnessSharpnessScreenState();
}

class _BrightnessSharpnessScreenState extends State<BrightnessSharpnessScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  double _brightness = 0; // -100..100
  double _contrast = 0;   // -100..100
  double _sharpness = 0;  // 0..5
  Uint8List? _previewBytes;
  bool _isPreviewProcessing = false;

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
    await _processAdjustments();
  }

  void _removeImage() => setState(() => _imageFile = null);

  Future<void> _processAdjustments() async {
    if (_imageFile == null) return;
    if (_brightness.round() == 0 && _contrast.round() == 0 && _sharpness.round() == 0) {
      if (!mounted) return;
      setState(() { _previewBytes = null; _isPreviewProcessing = false; });
      return;
    }
    setState(() => _isPreviewProcessing = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw 'Unsupported image format';
      final b = (1.0 + (_brightness / 100.0)).clamp(0.0, 2.0);
      final c = (1.0 + (_contrast / 100.0)).clamp(0.0, 2.0);
      const maxSide = 1024;
      var working = decoded;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        working = decoded.width >= decoded.height
            ? img.copyResize(decoded, width: maxSide)
            : img.copyResize(decoded, height: maxSide);
      } else {
        working = img.copyResize(decoded, width: decoded.width, height: decoded.height);
      }
      working = img.adjustColor(working, brightness: b, contrast: c);
      final sharpInt = _sharpness.round();
      if (sharpInt > 0) {
        const List<num> kernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];
        for (int i = 0; i < sharpInt; i++) {
          working = img.convolution(working, filter: kernel, div: 1, offset: 0);
        }
      }
      final out = Uint8List.fromList(img.encodePng(working));
      if (!mounted) return;
      setState(() => _previewBytes = out);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adjust error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPreviewProcessing = false);
    }
  }

  Future<void> _saveAdjustedImage() async {
    try {
      if (_previewBytes == null) await _processAdjustments();
      if (_previewBytes == null) throw 'No preview to save';
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_previewBytes!);
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList('downloadedFiles') ?? [];
      downloaded.add(fileName);
      await prefs.setStringList('downloadedFiles', downloaded);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to Downloads: $fileName'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, {ValueChanged<double>? onChangeEnd}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.white)),
      ]),
      Slider(value: value, min: min, max: max, divisions: (max - min).toInt(), label: value.toStringAsFixed(0), onChanged: onChanged, onChangeEnd: onChangeEnd),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Brightness/Sharpness', style: TextStyle(color: Colors.white)),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _isPreviewProcessing
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : (_previewBytes != null ? Image.memory(_previewBytes!, fit: BoxFit.contain) : Image.file(_imageFile!, fit: BoxFit.contain)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSlider('Brightness', _brightness, -100, 100, (v) => setState(() => _brightness = v), onChangeEnd: (_) => _processAdjustments()),
                  _buildSlider('Contrast', _contrast, -100, 100, (v) => setState(() => _contrast = v), onChangeEnd: (_) => _processAdjustments()),
                  _buildSlider('Sharpness', _sharpness, 0, 5, (v) => setState(() => _sharpness = v), onChangeEnd: (_) => _processAdjustments()),
                  const SizedBox(height: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.upload_file), label: const Text('Change Image')),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _isPreviewProcessing ? null : _saveAdjustedImage, child: const Text('Save')),
                ]),
          ),
        ),
      ),
    );
  }
}
