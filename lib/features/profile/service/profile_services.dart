// Location: agrivana\lib\features\profile\service\profile_services.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class SellerService {
  static Future<ApiResult> getStoreInfo() => ApiService.get(ApiConfig.sellerStore, auth: true);
  static Future<ApiResult> updateStore(Map<String, dynamic> data) =>
      ApiService.put(ApiConfig.sellerStore, body: data, auth: true);
  static Future<ApiResult> deleteStore() =>
      ApiService.delete(ApiConfig.sellerStore, auth: true);

  static Future<ApiResult> getStoreLocation() => ApiService.get(ApiConfig.sellerStoreLocation, auth: true);
  static Future<ApiResult> updateStoreLocation(Map<String, dynamic> data) =>
      ApiService.put(ApiConfig.sellerStoreLocation, body: data, auth: true);

  static Future<ApiResult> getMyProducts() =>
      ApiService.get(ApiConfig.sellerProducts, auth: true);
  static Future<ApiResult> updateProduct(String id, Map<String, dynamic> data) =>
      ApiService.put('${ApiConfig.sellerProducts}/$id', body: data, auth: true);
  static Future<ApiResult> deleteProduct(String id) =>
      ApiService.delete('${ApiConfig.sellerProducts}/$id', auth: true);

  static Future<ApiResult> getSellerOrders({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.sellerOrders, query: query, auth: true);
  static Future<ApiResult> getOrderDetail(String id) =>
      ApiService.get('${ApiConfig.sellerOrders}/$id', auth: true);
  static Future<ApiResult> processOrder(String id) =>
      ApiService.post('${ApiConfig.sellerOrders}/$id/process', auth: true);
  static Future<ApiResult> shipOrder(String id, Map<String, dynamic> data) =>
      ApiService.post('${ApiConfig.sellerOrders}/$id/ship', body: data, auth: true);
  static Future<ApiResult> getReportSummary({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.sellerReports, query: query, auth: true);
  static Future<ApiResult> requestWithdraw(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.sellerWithdraw, body: data, auth: true);
  static Future<ApiResult> replyReview(String reviewId, String body) =>
      ApiService.post('${ApiConfig.sellerReviews}/$reviewId/reply', body: {'reply': body}, auth: true);
}

class SubscriptionService {
  static Future<ApiResult> getPlans() => ApiService.get(ApiConfig.subscriptionPlans);
  static Future<ApiResult> getMySubscription() => ApiService.get(ApiConfig.subscriptionMy, auth: true);
}

class BannerService {
  static Future<ApiResult> getActiveBanners() => ApiService.get(ApiConfig.bannersActive);
  static Future<ApiResult> trackImpression(String id) =>
      ApiService.post('${ApiConfig.bannersActive.replaceAll('/active', '')}/$id/impression');
  static Future<ApiResult> trackClick(String id) =>
      ApiService.post('${ApiConfig.bannersActive.replaceAll('/active', '')}/$id/click');
}
