// Location: agrivana\lib\features\shop\service\shipping_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

/// Service to calculate shipping cost by calling api.co.id directly.
class ShippingService {
  static const _apiBaseUrl = 'https://use.api.co.id';
  static const _apiKey = '3i8RB3sYgI1F1wctRxNBi0WWmHucDNOg48hGBGOPVi2uPbDbun';

  /// Call api.co.id directly with origin + destination village codes.
  static Future<ApiResult> getShippingCost({
    required String originVillageCode,
    required String destinationVillageCode,
    required double weightKg,
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/expedition/shipping-cost').replace(
        queryParameters: {
          'origin_village_code': originVillageCode,
          'destination_village_code': destinationVillageCode,
          'weight': weightKg.toString(),
        },
      );

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'x-api-co-id': _apiKey,
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final isSuccess = json['is_success'] == true;
        if (isSuccess && json['data'] != null) {
          return ApiResult(success: true, message: 'Success', data: json['data']);
        } else {
          return ApiResult(success: false, message: json['message'] ?? 'Gagal mendapatkan ongkir');
        }
      } else {
        return ApiResult(success: false, message: 'Error ${response.statusCode}: Gagal menghitung ongkir');
      }
    } catch (e) {
      return ApiResult(success: false, message: 'Gagal terhubung ke layanan pengiriman: $e');
    }
  }

  /// Legacy: backend proxy (kept for backward compatibility).
  static Future<ApiResult> getShippingCostByStore({
    required String storeId,
    required String destinationVillageCode,
    required double weightKg,
  }) async {
    return ApiService.get(
      ApiConfig.shippingCost,
      query: {
        'storeId': storeId,
        'destination': destinationVillageCode,
        'weight': weightKg.toString(),
      },
      auth: true,
    );
  }
}
