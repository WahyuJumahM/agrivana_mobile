// Location: agrivana\lib\features\chatbot\service\chatbot_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class ChatbotService {
  static Future<ApiResult> sendMessage(String message, {String? imageBase64}) {
    final body = {'message': message};
    if (imageBase64 != null) body['imageBase64'] = imageBase64;
    return ApiService.post(ApiConfig.chatMessage, body: body, auth: true);
  }
  static Future<ApiResult> getHistory() => ApiService.get(ApiConfig.chatHistory, auth: true);
  static Future<ApiResult> clearSession() => ApiService.delete(ApiConfig.chatClear, auth: true);
}
