// Location: agrivana\lib\features\shop\service\order_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

// â”€â”€â”€ ORDER SERVICE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class OrderService {
  static Future<ApiResult> checkout(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.checkout, body: data, auth: true);
  static Future<ApiResult> getOrders({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.orders, query: query, auth: true);
  static Future<ApiResult> confirmReceive(String id) =>
      ApiService.post('${ApiConfig.orders}/$id/confirm', auth: true);
  static Future<ApiResult> getShippingCost(Map<String, String> query) =>
      ApiService.get(ApiConfig.shippingCost, query: query, auth: true);
}
