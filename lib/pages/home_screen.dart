import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6C63FF); // violet accent
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(255, 189, 239, 252), // deep navy
        Color.fromARGB(255, 69, 96, 99), // slate
        Color.fromARGB(255, 44, 66, 73), // muted indigo
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 187, 255).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(Icons.image_search, color: const Color.fromARGB(255, 255, 255, 255), size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'EDIT IMAGE USING AI FOR FREE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Upload an image to get started — fast, simple and free.',
                                  style: TextStyle(
                                    color: Color(0xFFB6C0D9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Main upload card
                    Card(
                      color: Colors.white.withOpacity(0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_imageFile == null) ...[
                              const SizedBox(height: 6),
                              Icon(Icons.image_outlined, size: 96, color: Colors.white70),
                              const SizedBox(height: 16),
                              Text(
                                'No image selected',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _pickFromGallery,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('Upload from gallery'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 5, 133, 168),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                height: 360,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_imageFile!, fit: BoxFit.contain, width: double.infinity),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('Change'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Footnote / CTA
                    Text(
                      'IMPRO© All Rights Reserved',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}