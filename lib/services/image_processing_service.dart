import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ImageProcessingService {
  static const String _baseUrl = 'https://ccc.anurag11.me';
  static const int _maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB limit

  /// Validate file size before uploading
  static Map<String, dynamic> validateFileSize(File imageFile) {
    try {
      final fileSizeInBytes = imageFile.lengthSync();
      
      if (fileSizeInBytes > _maxFileSizeInBytes) {
        final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(2);
        final maxSizeInMB = (_maxFileSizeInBytes / (1024 * 1024)).toStringAsFixed(0);
        return {
          'valid': false,
          'error': 'Image size ($fileSizeInMB MB) exceeds maximum limit of $maxSizeInMB MB. Please use a smaller image.',
        };
      }
      
      return {'valid': true};
    } catch (e) {
      return {
        'valid': false,
        'error': 'Could not verify file size: $e',
      };
    }
  }

  /// Detect objects in an image using YOLO
  static Future<Map<String, dynamic>> detectObjects(File imageFile) async {
    // Validate file size first
    final validation = validateFileSize(imageFile);
    if (!validation['valid']) {
      return {
        'success': false,
        'error': validation['error'],
      };
    }

    try {
      final userId = await _getUserId();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/detect'))
        ..fields['_id'] = userId
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      try {
        final jsonData = jsonDecode(responseData);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': jsonData,
            'outputUrl': '${_baseUrl}${jsonData['output_url']}',
            'detections': jsonData['detections'] ?? [],
            'objectTypes': jsonData['object_types'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': jsonData['error'] ?? 'Detection failed',
          };
        }
      } catch (e) {
        // If response is not JSON, return error
        return {
          'success': false,
          'error': 'Server returned invalid response. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Remove background from an image
  static Future<Map<String, dynamic>> removeBackground(File imageFile) async {
    // Validate file size first
    final validation = validateFileSize(imageFile);
    if (!validation['valid']) {
      return {
        'success': false,
        'error': validation['error'],
      };
    }

    try {
      final userId = await _getUserId();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/remove-bg'))
        ..fields['_id'] = userId
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      try {
        final jsonData = jsonDecode(responseData);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': jsonData,
            'outputUrl': '${_baseUrl}${jsonData['output_url']}',
          };
        } else {
          return {
            'success': false,
            'error': jsonData['error'] ?? 'Background removal failed',
          };
        }
      } catch (e) {
        // If response is not JSON, return error
        return {
          'success': false,
          'error': 'Server returned invalid response. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Extract text from an image using OCR
  static Future<Map<String, dynamic>> extractText(File imageFile) async {
    // Validate file size first
    final validation = validateFileSize(imageFile);
    if (!validation['valid']) {
      return {
        'success': false,
        'error': validation['error'],
      };
    }

    try {
      final userId = await _getUserId();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/extract-text'))
        ..fields['_id'] = userId
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      try {
        final jsonData = jsonDecode(responseData);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': jsonData,
            'extractedText': jsonData['extracted_text'] ?? '',
          };
        } else {
          return {
            'success': false,
            'error': jsonData['error'] ?? 'Text extraction failed',
          };
        }
      } catch (e) {
        // If response is not JSON, return error
        return {
          'success': false,
          'error': 'Server returned invalid response. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Get all processed images for the user
  static Future<Map<String, dynamic>> findAllOutputs() async {
    try {
      final userId = await _getUserId();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/find-all'))
        ..fields['_id'] = userId;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonData,
          'images': jsonData['images'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': jsonData['error'] ?? 'Failed to fetch outputs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Get user ID from SharedPreferences (uses email or creates a unique ID)
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    
    if (userId == null) {
      // Try to get email from saved user data
      final userEmail = prefs.getString('userEmail');
      if (userEmail != null) {
        userId = userEmail.replaceAll('.', '_').replaceAll('@', '_');
      } else {
        // Generate a unique ID based on timestamp
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      }
      await prefs.setString('userId', userId);
    }
    
    return userId;
  }

  /// Download/retrieve a processed image from the server
  static String getImageUrl(String outputPath) {
    return '$_baseUrl$outputPath';
  }

  /// Download image from URL and save to device
  static Future<Map<String, dynamic>> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'message': 'Image downloaded successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to download image (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Download error: $e',
      };
    }
  }
}
