import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploadService {
  // Using imgbb free image hosting service
  // Get your own API key from https://api.imgbb.com/
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';
  static const String _apiKey =
      '46c337c93c8062b72cdd527bd4419c6c'; // Free tier API key

  /// Upload image to imgbb and return URL
  /// For production: implement upload to your own server
  static Future<String> uploadImage(File imageFile) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create request with timeout
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
          'expiration': '600', // 10 minutes expiration for free tier
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Return display URL
          return data['data']['display_url'] as String;
        } else {
          throw Exception(data['error']['message'] ?? 'Upload failed');
        }
      }

      throw Exception('Server returned ${response.statusCode}');
    } on http.ClientException catch (e) {
      throw Exception('Lỗi kết nối: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi upload: ${e.toString()}');
    }
  }

  /// Alternative: Upload to your own backend
  static Future<String> uploadToBackend(File imageFile, String token) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('YOUR_BACKEND_URL/upload/avatar'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      }

      throw Exception('Failed to upload image');
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }
}
