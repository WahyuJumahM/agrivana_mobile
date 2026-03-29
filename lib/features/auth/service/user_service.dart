// Location: agrivana\lib\features\auth\service\user_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class UserService {
  // â”€â”€â”€ Profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getProfile() => ApiService.get(ApiConfig.userMe, auth: true);
  static Future<ApiResult> updateProfile(Map<String, dynamic> data) => ApiService.put(ApiConfig.userMe, body: data, auth: true);
  static Future<ApiResult> changePassword(String current, String newPass) =>
      ApiService.post(ApiConfig.changePassword, body: {'currentPassword': current, 'newPassword': newPass}, auth: true);
  static Future<ApiResult> saveFcmToken(String token) =>
      ApiService.post(ApiConfig.fcmToken, body: {'token': token}, auth: true);

  // â”€â”€â”€ Addresses â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getAddresses() => ApiService.get(ApiConfig.addresses, auth: true);
  static Future<ApiResult> addAddress(Map<String, dynamic> data) => ApiService.post(ApiConfig.addresses, body: data, auth: true);
  static Future<ApiResult> deleteAddress(String id) => ApiService.delete('${ApiConfig.addresses}/$id', auth: true);
  static Future<ApiResult> setPrimaryAddress(String id) => ApiService.put('${ApiConfig.addresses}/$id/primary', auth: true);

  // â”€â”€â”€ Wishlist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getWishlist() => ApiService.get(ApiConfig.wishlist, auth: true);
  static Future<ApiResult> toggleWishlist(String productId) => ApiService.post('${ApiConfig.wishlist}/$productId', auth: true);

  // â”€â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getNotifications() => ApiService.get(ApiConfig.notifications, auth: true);
  static Future<ApiResult> markNotificationsRead({List<String>? ids}) =>
      ApiService.post(ApiConfig.notificationsRead, body: ids != null ? {'ids': ids} : null, auth: true);

  // â”€â”€â”€ Reviews â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<ApiResult> getMyReviews() => ApiService.get(ApiConfig.reviews, auth: true);
  static Future<ApiResult> createReview(Map<String, dynamic> data) => ApiService.post(ApiConfig.reviews, body: data, auth: true);
}
