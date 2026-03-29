// Location: agrivana\lib\features\education\service\article_service.dart
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class ArticleService {
  static Future<ApiResult> getCategories() => ApiService.get(ApiConfig.articleCategories);
  static Future<ApiResult> getArticles({Map<String, String>? query}) =>
      ApiService.get(ApiConfig.articles, query: query);
  static Future<ApiResult> getArticleBySlug(String slug) =>
      ApiService.get('${ApiConfig.articles}/$slug');
  static Future<ApiResult> toggleBookmark(String id) =>
      ApiService.post('${ApiConfig.articles}/$id/bookmark', auth: true);
  static Future<ApiResult> getBookmarks() => ApiService.get(ApiConfig.articleBookmarks, auth: true);
  static Future<ApiResult> getLearningPaths() => ApiService.get(ApiConfig.learningPaths);
  static Future<ApiResult> getLearningPathDetail(String id) =>
      ApiService.get('${ApiConfig.learningPaths}/$id');
  static Future<ApiResult> getModuleContent(String id) =>
      ApiService.get('${ApiConfig.learningPaths}/modules/$id');
  static Future<ApiResult> submitQuiz(String moduleId, Map<String, dynamic> answers) =>
      ApiService.post('${ApiConfig.learningPaths}/modules/$moduleId/quiz', body: answers, auth: true);
}
