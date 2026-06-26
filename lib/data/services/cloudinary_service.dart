import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Config keys - Replace these with actual Cloudinary credentials
  static const String cloudName = 'dpxjdlbiz';
  static const String uploadPreset = 'agorareports'; // Must be set to 'Unsigned' in Cloudinary dashboard

  /// Uploads local image bytes (highly compatible with web and mobile platforms).
  /// Returns the secure URL of the uploaded image on success.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception(
          'Error al subir a Cloudinary: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Falla en la conexión de Cloudinary: $e');
    }
  }

  /// Uploads a local image file path (standard for mobile devices).
  /// Returns the secure URL on success.
  Future<String> uploadImageFile(String filePath) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception(
          'Error al subir a Cloudinary: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Falla en la conexión de Cloudinary: $e');
    }
  }
}
