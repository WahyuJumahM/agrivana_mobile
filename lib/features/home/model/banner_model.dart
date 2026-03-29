// Location: agrivana\lib\features\home\model\banner_model.dart
class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionUrl;
  final String? actionLabel;

  BannerModel({required this.id, required this.title, this.subtitle, required this.imageUrl, this.actionUrl, this.actionLabel});

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id']?.toString() ?? '', title: json['title'] ?? '',
        subtitle: json['subtitle'], imageUrl: json['imageUrl'] ?? '',
        actionUrl: json['actionUrl'], actionLabel: json['actionLabel']);
}

class SubscriptionPlan {
  final String id;
  final String name;
  final int durationDays;
  final double price;
  final String? description;
  final bool isFeatured;

  SubscriptionPlan({required this.id, required this.name, required this.durationDays, required this.price, this.description, this.isFeatured = false});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id']?.toString() ?? '', name: json['name'] ?? '',
        durationDays: json['durationDays'] ?? 0, price: (json['price'] ?? 0).toDouble(),
        description: json['description'], isFeatured: json['isFeatured'] ?? false);
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? deepLink;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({required this.id, required this.type, required this.title, required this.body, this.deepLink, this.isRead = false, this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id']?.toString() ?? '', type: json['type'] ?? '',
        title: json['title'] ?? '', body: json['body'] ?? '',
        deepLink: json['deepLink'], isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null);
}
