// Location: agrivana\lib\features\shop\service\marketplace_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class MarketplaceService {
  // â”€â”€â”€ Products â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getProducts({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.products, query: query);
  static Future<ApiResult> getProductById(String id) =>
      ApiService.get('${ApiConfig.products}/$id');

  // â”€â”€â”€ Categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getCategories() => ApiService.get(ApiConfig.categories);

  // â”€â”€â”€ Stores â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> createStore(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.stores, body: data, auth: true);
  static Future<ApiResult> addProduct(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.products, body: data, auth: true);
}
