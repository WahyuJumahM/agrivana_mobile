// Location: agrivana\lib\features\community\model\community_model.dart
class CommunityChannel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;

  CommunityChannel({required this.id, required this.name, required this.slug, this.description, this.icon});

  factory CommunityChannel.fromJson(Map<String, dynamic> json) => CommunityChannel(
        id: json['id']?.toString() ?? '', name: json['name'] ?? '',
        slug: json['slug'] ?? '', description: json['description'], icon: json['icon']);
}

class CommunityPost {
  final String id;
  final String title;
  final String body;
  final String? authorName;
  final String? authorPhoto;
  final String? channelName;
  final bool isAnswered;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final List<String>? plantTags;
  final List<String>? photoUrls;
  final DateTime? createdAt;
  final bool? isLiked;

  CommunityPost({
    required this.id, required this.title, required this.body,
    this.authorName, this.authorPhoto, this.channelName,
    this.isAnswered = false, this.likeCount = 0, this.commentCount = 0,
    this.viewCount = 0, this.plantTags, this.photoUrls,
    this.createdAt, this.isLiked,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id']?.toString() ?? '', title: json['title'] ?? '',
        body: json['body'] ?? json['excerpt'] ?? '', authorName: json['authorName'] ?? json['author'],
        authorPhoto: json['authorPhoto'], channelName: json['channelName'],
        isAnswered: json['isAnswered'] ?? false,
        likeCount: json['likeCount'] ?? 0, commentCount: json['commentCount'] ?? 0,
        viewCount: json['viewCount'] ?? 0,
        plantTags: json['plantTags'] != null ? List<String>.from(json['plantTags']) : null,
        photoUrls: json['photoUrls'] != null ? List<String>.from(json['photoUrls']) : null,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        isLiked: json['isLiked'],
      );
}

class CommentModel {
  final String id;
  final String body;
  final String? authorName;
  final String? authorPhoto;
  final String? parentId;
  final int likeCount;
  final DateTime? createdAt;
  final List<CommentModel> replies;

  CommentModel({
    required this.id, required this.body, this.authorName, this.authorPhoto,
    this.parentId, this.likeCount = 0, this.createdAt, this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id']?.toString() ?? '', body: json['body'] ?? '',
        authorName: json['authorName'], authorPhoto: json['authorPhoto'],
        parentId: json['parentId']?.toString(), likeCount: json['likeCount'] ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        replies: json['replies'] != null
            ? (json['replies'] as List).map((r) => CommentModel.fromJson(r)).toList() : [],
      );
}
