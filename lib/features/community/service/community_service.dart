// Location: agrivana\lib\features\community\service\community_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class CommunityService {
  static Future<ApiResult> getChannels() => ApiService.get(ApiConfig.communityChannels);
  static Future<ApiResult> getPosts({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.communityPosts, query: query);
  static Future<ApiResult> getPostDetail(String id) =>
      ApiService.get('${ApiConfig.communityPosts}/$id');
  static Future<ApiResult> createPost(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.communityPosts, body: data, auth: true);
  static Future<ApiResult> deletePost(String id) =>
      ApiService.delete('${ApiConfig.communityPosts}/$id', auth: true);
  static Future<ApiResult> markAnswered(String id) =>
      ApiService.post('${ApiConfig.communityPosts}/$id/answered', auth: true);
  static Future<ApiResult> getComments(String postId) =>
      ApiService.get('${ApiConfig.communityPosts}/$postId/comments');
  static Future<ApiResult> addComment(String postId, Map<String, dynamic> data) =>
      ApiService.post('${ApiConfig.communityPosts}/$postId/comments', body: data, auth: true);
  static Future<ApiResult> toggleReaction(String postId, String type) =>
      ApiService.post('${ApiConfig.communityPosts}/$postId/react', body: {'type': type}, auth: true);
  static Future<ApiResult> toggleFollow(String targetUserId) =>
      ApiService.post('${ApiConfig.communityUsers}/$targetUserId/follow', auth: true);
  static Future<ApiResult> reportContent(Map<String, dynamic> data) =>
      ApiService.post(ApiConfig.communityReport, body: data, auth: true);
}
