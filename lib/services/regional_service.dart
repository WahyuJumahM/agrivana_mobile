import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for Indonesian regional data (api.co.id).
/// Cascading dropdown: Province → City → District → Village.
class RegionalService {
  static const String _baseUrl = 'https://use.api.co.id/regional/indonesia';
  static const Map<String, String> _headers = {
    'x-api-co-id': '3i8RB3sYgI1F1wctRxNBi0WWmHucDNOg48hGBGOPVi2uPbDbun'
  };

  /// Searches for villages directly from external API API.co.id
  /// The endpoint used: https://use.api.co.id/regional/indonesia/villages?name={query}
  static Future<ApiResult> searchVillages(String query) async {
    try {
      final qUpper = Uri.encodeComponent(query.toUpperCase().trim());
      
      final villageFuture = http.get(Uri.parse('$_baseUrl/villages?name=$qUpper'), headers: _headers);
      final districtFuture = http.get(Uri.parse('$_baseUrl/districts?name=$qUpper'), headers: _headers);
      final regencyFuture = http.get(Uri.parse('$_baseUrl/regencies?name=$qUpper'), headers: _headers);

      final responses = await Future.wait([villageFuture, districtFuture, regencyFuture]);
      
      final List<Map<String, dynamic>> combined = [];

      // 1. Parse Villages
      if (responses[0].statusCode == 200) {
        final body = jsonDecode(responses[0].body);
        if (body['is_success'] == true && body['data'] is List) {
          for (var e in body['data']) {
            if (e is Map) {
              combined.add({
                'code': e['code']?.toString() ?? '',
                'village': e['name']?.toString() ?? '',
                'district': e['district']?.toString() ?? '',
                'regency': (e['regency']?.toString() ?? '').replaceAll('KOTA ', '').replaceAll('KABUPATEN ', ''),
                'province': e['province']?.toString() ?? '',
              });
            }
          }
        }
      }

      // 2. Parse Districts
      if (responses[1].statusCode == 200) {
        final body = jsonDecode(responses[1].body);
        if (body['is_success'] == true && body['data'] is List) {
          for (var e in body['data']) {
            if (e is Map) {
              combined.add({
                'code': e['code']?.toString() ?? '',
                'village': 'Semua Kelurahan',
                'district': e['name']?.toString() ?? '',
                'regency': (e['regency']?.toString() ?? '').replaceAll('KOTA ', '').replaceAll('KABUPATEN ', ''),
                'province': e['province']?.toString() ?? '',
              });
            }
          }
        }
      }

      // 3. Parse Regencies
      if (responses[2].statusCode == 200) {
        final body = jsonDecode(responses[2].body);
        if (body['is_success'] == true && body['data'] is List) {
          for (var e in body['data']) {
            if (e is Map) {
              combined.add({
                'code': e['code']?.toString() ?? '',
                'village': 'Semua Kelurahan',
                'district': 'Semua Kecamatan',
                'regency': (e['name']?.toString() ?? '').replaceAll('KOTA ', '').replaceAll('KABUPATEN ', ''),
                'province': e['province']?.toString() ?? '',
              });
            }
          }
        }
      }

      if (combined.isNotEmpty) {
        return ApiResult(success: true, message: 'Success', data: combined);
      }
      return ApiResult(success: false, message: 'Lokasi tidak ditemukan', data: <dynamic>[]);
    } catch (e) {
      return ApiResult(success: false, message: 'Terjadi kesalahan jaringan rute external');
    }
  }
}
