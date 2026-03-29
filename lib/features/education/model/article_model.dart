// Location: agrivana\lib\features\education\model\article_model.dart
class ArticleModel {
  final String id;
  final String title;
  final String slug;
  final String? coverImage;
  final String? excerpt;
  final String? body;
  final bool isPremium;
  final int? readTimeMin;
  final String? difficulty;
  final int viewCount;
  final List<String>? plantTags;
  final String? categoryName;
  final String? authorName;
  final DateTime? publishedAt;
  final bool? truncated;
  final bool isBookmarked;

  ArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverImage,
    this.excerpt,
    this.body,
    this.isPremium = false,
    this.readTimeMin,
    this.difficulty,
    this.viewCount = 0,
    this.plantTags,
    this.categoryName,
    this.authorName,
    this.publishedAt,
    this.truncated,
    this.isBookmarked = false,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        slug: json['slug'] ?? '',
        coverImage: json['coverImage'] ?? json['cover'],
        excerpt: json['excerpt'],
        body: json['body'],
        isPremium: json['isPremium'] ?? false,
        readTimeMin: json['readTimeMin'] ?? json['readTime'],
        difficulty: json['difficulty'],
        viewCount: json['viewCount'] ?? 0,
        plantTags: json['plantTags'] != null
            ? List<String>.from(json['plantTags'])
            : null,
        categoryName: json['categoryName'] ?? json['category'],
        authorName: json['authorName'] ?? json['author'],
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'])
            : null,
        truncated: json['truncated'] ?? json['locked'],
        isBookmarked: json['isBookmarked'] ?? false,
      );

  /// Parse the detail endpoint response which wraps article in nested object.
  factory ArticleModel.fromDetailJson(Map<String, dynamic> json) {
    final article = json['article'] ?? json;
    final body = json['body'] ?? article['body'];
    final locked = json['locked'] ?? false;

    return ArticleModel(
      id: article['id']?.toString() ?? '',
      title: article['title'] ?? '',
      slug: article['slug'] ?? '',
      coverImage: article['coverImage'] ?? article['cover'],
      excerpt: article['excerpt'],
      body: body,
      isPremium: article['isPremium'] ?? false,
      readTimeMin: article['readTimeMin'] ?? article['readTime'],
      difficulty: article['difficulty'],
      viewCount: article['viewCount'] ?? 0,
      plantTags: article['plantTags'] != null
          ? List<String>.from(article['plantTags'])
          : null,
      categoryName: article['categoryName'] ?? article['category'],
      authorName: article['authorName'] ?? article['author'],
      publishedAt: article['publishedAt'] != null
          ? DateTime.tryParse(article['publishedAt'])
          : null,
      truncated: locked,
      isBookmarked: article['isBookmarked'] ?? false,
    );
  }

  ArticleModel copyWith({bool? isBookmarked}) => ArticleModel(
        id: id,
        title: title,
        slug: slug,
        coverImage: coverImage,
        excerpt: excerpt,
        body: body,
        isPremium: isPremium,
        readTimeMin: readTimeMin,
        difficulty: difficulty,
        viewCount: viewCount,
        plantTags: plantTags,
        categoryName: categoryName,
        authorName: authorName,
        publishedAt: publishedAt,
        truncated: truncated,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}

class ContentCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  ContentCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory ContentCategoryModel.fromJson(Map<String, dynamic> json) =>
      ContentCategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        icon: json['icon'],
      );
}
