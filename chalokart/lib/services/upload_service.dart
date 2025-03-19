import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadService {
  final String baseUrl = 'http://localhost:8000/api'; // Update with your API URL

  Future<Map<String, dynamic>> uploadIdCard(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-id-card/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'id_card',
          file.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to upload ID card',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading ID card: $e',
      };
    }
  }

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }
} 