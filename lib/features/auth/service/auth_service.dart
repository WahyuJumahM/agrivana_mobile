// Location: agrivana\lib\features\auth\service\auth_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class AuthService {
  static Future<ApiResult> register(String name, String email, String phone, String password) async {
    return ApiService.post(ApiConfig.register, body: {
      'name': name, 'email': email, 'phone': phone, 'password': password,
    });
  }

  static Future<ApiResult> verifyOtp(String identifier, String otp, String otpType) async {
    return ApiService.post(ApiConfig.verifyOtp, body: {
      'identifier': identifier, 'otp': otp, 'otpType': otpType,
    });
  }

  static Future<ApiResult> resendOtp(String identifier) async {
    return ApiService.post(ApiConfig.resendOtp, body: {'identifier': identifier});
  }

  static Future<ApiResult> login(String identifier, String password) async {
    return ApiService.post(ApiConfig.login, body: {
      'identifier': identifier, 'password': password,
    });
  }

  static Future<ApiResult> forgotPassword(String identifier) async {
    return ApiService.post(ApiConfig.forgotPassword, body: {'identifier': identifier});
  }

  static Future<ApiResult> resetPassword(String identifier, String otp, String newPassword) async {
    return ApiService.post(ApiConfig.resetPassword, body: {
      'identifier': identifier, 'otp': otp, 'newPassword': newPassword,
    });
  }

  static Future<ApiResult> logout() async {
    final rt = ApiService.refreshToken;
    if (rt == null) return ApiResult(success: true, message: 'OK');
    return ApiService.post(ApiConfig.logout, body: {'refreshToken': rt}, auth: true);
  }

  static Future<ApiResult> logoutAll() async {
    return ApiService.post(ApiConfig.logoutAll, auth: true);
  }
}
