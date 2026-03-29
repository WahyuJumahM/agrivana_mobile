// Location: agrivana\lib\features\shop\service\chat_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class ChatService {
  /// Create or get conversation with another user
  static Future<ApiResult> getOrCreateConversation(String otherUserId) async {
    return ApiService.post(
      ApiConfig.chatConversations,
      body: {'otherUserId': otherUserId},
      auth: true,
    );
  }

  /// Get list of all conversations
  static Future<ApiResult> getConversations() async {
    return ApiService.get(ApiConfig.chatConversations, auth: true);
  }

  /// Get messages for a conversation
  static Future<ApiResult> getMessages(String conversationId, {int page = 1}) async {
    return ApiService.get(
      '${ApiConfig.chatConversations}/$conversationId/messages',
      query: {'page': page.toString()},
      auth: true,
    );
  }

  /// Send a message in a conversation
  static Future<ApiResult> sendMessage(String conversationId, String content) async {
    return ApiService.post(
      '${ApiConfig.chatConversations}/$conversationId/messages',
      body: {'content': content},
      auth: true,
    );
  }
}
