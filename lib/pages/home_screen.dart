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
  int _currentIndex = 0;

  final Color _accent = const Color(0xFF6C63FF);

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  void _removeImage() => setState(() => _imageFile = null);

  // Home page content (your original UI)
  Widget _buildHomeContent() {
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(255, 189, 239, 252),
        Color.fromARGB(255, 69, 96, 99),
        Color.fromARGB(255, 44, 66, 73),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: bgGradient),
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
                          child: Icon(Icons.image_search, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'FOTOFIX',
                                textAlign: TextAlign.center,
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
                                    backgroundColor: _accent,
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
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder Downloads page
  Widget _buildDownloadsContent() {
    return Container(
      color: const Color.fromARGB(255, 18, 20, 22),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_rounded, size: 84, color: _accent),
              const SizedBox(height: 16),
              Text('Downloads', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your downloaded images and edits will appear here.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder Search page
  Widget _buildSearchContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFeef2ff), Color(0xFFcfe8ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 80),
                const SizedBox(height: 12),
                const Text('Search', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search templates, styles or previous edits',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder Profile page
  Widget _buildProfileContent() {
    return Container(
      color: const Color(0xFF0f1720),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 46, child: Icon(Icons.person, size: 46)),
              const SizedBox(height: 12),
              Text('Shubham', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('shubham@example.com', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildDownloadsContent();
      case 2:
        return _buildSearchContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep scaffold background transparent to let gradients show
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black.withOpacity(0.55),
              selectedItemColor: _accent,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
              items: [
                _navItem(Icons.home_rounded, 'Home'),
                _navItem(Icons.download_rounded, 'Downloads'),
                _navItem(Icons.search_rounded, 'Search'),
                _navItem(Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
