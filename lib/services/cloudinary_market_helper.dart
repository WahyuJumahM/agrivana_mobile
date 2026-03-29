// Location: agrivana\lib\utils\cloudinary_helper.dart
import 'dart:convert';
// import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CloudinaryHelper {
  /// Uploads a file to Cloudinary and returns the secure_url.
  /// [filePath] — absolute path of the picked image.
  /// [preset] — upload preset (e.g. 'profiles_market', 'products').
  static Future<String?> upload(String filePath, {String? preset}) async {
    final uploadPreset = preset ?? ApiConfig.marketPreset;
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${ApiConfig.cloudName}/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = jsonDecode(await response.stream.bytesToString());
        return body['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
