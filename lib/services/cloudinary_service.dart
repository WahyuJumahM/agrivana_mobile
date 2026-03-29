// Location: agrivana\lib\services\cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CloudinaryService {
  static const String _cloudName = ApiConfig.cloudName;
  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image to Cloudinary using unsigned preset.
  /// Returns the secure URL of the uploaded image.
  static Future<String?> uploadImage(
    File file, {
    String preset = ApiConfig.otherPreset,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = preset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respBody = await response.stream.bytesToString();
        final json = jsonDecode(respBody);
        return json['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload profile photo
  static Future<String?> uploadProfilePhoto(File file) =>
      uploadImage(file, preset: ApiConfig.profilePreset);

  /// Upload product photo
  static Future<String?> uploadProductPhoto(File file) =>
      uploadImage(file, preset: ApiConfig.productPreset);

  /// Upload plant cover photo
  static Future<String?> uploadPlantPhoto(File file) =>
      uploadImage(file, preset: ApiConfig.plantPreset);

  /// Upload plant growth log photo
  static Future<String?> uploadPlantLogPhoto(File file) =>
      uploadImage(file, preset: ApiConfig.plantLogPreset);
}
