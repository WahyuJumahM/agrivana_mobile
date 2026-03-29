// Location: agrivana\lib\services\api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static String? _accessToken;
  static String? _refreshToken;

  /// Stream that emits when user session expires (401 after refresh fails).
  /// main.dart listens to this to navigate to login.
  static final StreamController<void> onSessionExpired =
      StreamController<void>.broadcast();

  // â”€â”€â”€ Token Management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static bool get isLoggedIn => _accessToken != null;

  // â”€â”€â”€ Headers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // â”€â”€â”€ Core Request Methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> get(
    String endpoint, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    return _request('GET', endpoint, query: query, auth: auth);
  }

  static Future<ApiResult> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _request('POST', endpoint, body: body, auth: auth);
  }

  static Future<ApiResult> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _request('PUT', endpoint, body: body, auth: auth);
  }

  static Future<ApiResult> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    return _request('DELETE', endpoint, body: body, auth: auth);
  }

  // â”€â”€â”€ Internal Request Handler â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> _request(
    String method,
    String endpoint, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool auth = false,
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$endpoint',
      ).replace(queryParameters: query);

      http.Response response;
      final headers = _headers(auth: auth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;
        default:
          return ApiResult(success: false, message: 'Invalid method');
      }

      // Handle 401 - Try refresh
      if (response.statusCode == 401 && !isRetry && auth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _request(
            method,
            endpoint,
            query: query,
            body: body,
            auth: auth,
            isRetry: true,
          );
        } else {
          await clearTokens();
          onSessionExpired.add(null);
          return ApiResult(
            success: false,
            message: 'Sesi telah berakhir. Silakan login kembali.',
          );
        }
      }

      return _parseResponse(response);
    } catch (e) {
      return ApiResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  // /*refersh token
  static Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          await saveTokens(
            json['data']['accessToken'],
            json['data']['refreshToken'],
          );
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // â”€â”€â”€ Response Parser â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static ApiResult _parseResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      final success = json['success'] == true;
      final message = json['message'] ?? '';
      final data = json['data'];

      switch (response.statusCode) {
        case 200:
        case 201:
          return ApiResult(success: success, message: message, data: data);
        case 400:
          return ApiResult(success: false, message: message);
        case 401:
          return ApiResult(
            success: false,
            message: message.isNotEmpty ? message : 'Unauthorized',
          );
        case 403:
          return ApiResult(
            success: false,
            message:
                'Anda tidak memiliki akses. Upgrade ke Premium untuk fitur ini.',
            statusCode: 403,
          );
        case 404:
          return ApiResult(
            success: false,
            message: 'Tidak ditemukan.',
            statusCode: 404,
          );
        case 429:
          return ApiResult(
            success: false,
            message: 'Batas penggunaan tercapai. Coba lagi nanti.',
            statusCode: 429,
          );
        default:
          return ApiResult(
            success: false,
            message: 'Terjadi kesalahan. Coba lagi nanti.',
            statusCode: response.statusCode,
          );
      }
    } catch (_) {
      return ApiResult(
        success: false,
        message: 'Terjadi kesalahan pada server.',
        statusCode: response.statusCode,
      );
    }
  }
}

// â”€â”€â”€ API Result Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ApiResult {
  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiResult({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });
}
