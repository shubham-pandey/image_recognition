import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:final_task/widgets/app_background.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _selectedFormat = 'jpg';
  bool _isConverting = false;

  static const List<String> _formats = ['jpg', 'png', 'bmp', 'tga', 'gif'];

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  Future<void> _convertAndSave() async {
    if (_imageFile == null) return;
    setState(() => _isConverting = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw 'Unsupported image format';

      Uint8List outBytes;
      String ext = _selectedFormat;
  if (ext == 'jpg' || ext == 'jpeg') {
        outBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
        ext = 'jpg';
      } else if (ext == 'png') {
        outBytes = Uint8List.fromList(img.encodePng(decoded));
      } else if (ext == 'bmp') {
        outBytes = Uint8List.fromList(img.encodeBmp(decoded));
      } else if (ext == 'tga') {
        outBytes = Uint8List.fromList(img.encodeTga(decoded));
      } else if (ext == 'gif') {
        outBytes = Uint8List.fromList(img.encodeGif(decoded));
      } else {
        throw 'Unsupported format: $ext';
      }

      final fileName = 'converted_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(outBytes);

      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList('downloadedFiles') ?? [];
      downloaded.add(fileName);
      await prefs.setStringList('downloadedFiles', downloaded);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to Downloads: $fileName'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Convert error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Image Converter', style: TextStyle(color: Colors.white)),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Format:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedFormat,
                        dropdownColor: Colors.black,
                        items: _formats
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.toUpperCase(), style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedFormat = v ?? 'jpg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isConverting ? null : _convertAndSave,
                    icon: _isConverting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt),
                    label: Text(_isConverting ? 'Converting…' : 'Convert & Download'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
