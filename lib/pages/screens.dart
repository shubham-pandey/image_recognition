import 'dart:io';
import 'dart:convert';
import 'package:final_task/pages/edit.dart';
import 'package:final_task/feature/find_objects.dart';
import 'package:final_task/feature/text_extractor.dart';
import 'package:final_task/feature/remove_background.dart';
import 'package:final_task/feature/image_converter.dart';
import 'package:final_task/feature/brightness_sharpness.dart';
import 'package:final_task/feature/crop.dart';
import 'package:final_task/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:final_task/config.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPage(imageFile: _imageFile!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      //for scrolling
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image for Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 35,
              children: [
                _FeatureBox(
                  icon: Icons.search,
                  label: 'Find Objects',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FindObjectsScreen(),
                    ),
                  ),
                ),
                _FeatureBox(
                  icon: Icons.text_fields,
                  label: 'Text Extractor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TextExtractorScreen(),
                    ),
                  ),
                ),
                _FeatureBox(
                  icon: Icons.brush,
                  label: 'Remove Background',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RemoveBackgroundScreen(),
                    ),
                  ),
                ),
                _FeatureBox(
                  icon: Icons.transform,
                  label: 'Image Converter',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImageConverterScreen(),
                    ),
                  ),
                ),
                _FeatureBox(
                  icon: Icons.brightness_6,
                  label: 'Brightness/Sharpness',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BrightnessSharpnessScreen(),
                    ),
                  ),
                ),
                _FeatureBox(
                  icon: Icons.crop,
                  label: 'Crop',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CropComingSoonScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  List<String> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _downloadedFiles = prefs.getStringList('downloadedFiles') ?? [];
    });
  }

  Future<void> _refreshDownloads() async {
    await _loadDownloadedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDownloads,
      child: _downloadedFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done_rounded, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing Downloaded',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloaded images will appear here',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _downloadedFiles.length,
              itemBuilder: (context, index) {
                final fileName = _downloadedFiles[index];
                final downloadsDir = Directory('/storage/emulated/0/Download');
                final file = File('${downloadsDir.path}/$fileName');

                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.image_rounded, color: Colors.white70),
                    title: Text(
                      fileName,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: FutureBuilder<FileStat>(
                      future: file.stat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final size = snapshot.data!.size;
                          final sizeInMB = (size / (1024 * 1024)).toStringAsFixed(2);
                          return Text(
                            '$sizeInMB MB',
                            style: const TextStyle(color: Colors.white54),
                          );
                        }
                        return const Text('');
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () async {
                        if (await file.exists()) {
                          await file.delete();
                        }
                        final prefs = await SharedPreferences.getInstance();
                        _downloadedFiles.removeAt(index);
                        await prefs.setStringList('downloadedFiles', _downloadedFiles);
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      // Can add preview or open file functionality here
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userData = {
        'name': prefs.getString('userName') ?? 'User',
        // login.dart stores 'userEmail'
        'email': prefs.getString('userEmail') ?? 'Not available',
        'token': prefs.getString('accessToken') ?? '',
      };
      _loading = false;
    });
  }

  Future<void> _showUpdatePasswordDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _updatePassword,
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    final token = _userData['token'] as String? ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/v1/auth/reset-password/$token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'password': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully'), backgroundColor: Colors.green),
        );
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        String message = 'Failed to update password';
        try {
          final body = json.decode(response.body);
          if (body is Map && body['message'] is String) message = body['message'];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _ProfileInfoCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: _userData['name'] ?? '',
                  ),
                  const SizedBox(height: 16),
                  _ProfileInfoCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _userData['email'] ?? '',
                  ),
                  const SizedBox(height: 24),
                  _ProfileInfoCard(
                    icon: Icons.password_rounded,
                    label: 'Password',
                    value: '••••••••',
                    onTap: _showUpdatePasswordDialog,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('accessToken');
                        await prefs.remove('userName');
                        await prefs.remove('userEmail');
                        
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _FeatureBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FeatureBox({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );

    return onTap == null
        ? card
        : GestureDetector(
            onTap: onTap,
            child: card,
          );
  }
}