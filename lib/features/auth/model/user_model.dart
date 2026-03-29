// Location: agrivana\lib\features\auth\model\user_model.dart
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? bio;
  final String? profilePhoto;
  final String? locationCity;
  final bool isPremium;
  final bool hasStore;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.bio,
    this.profilePhoto,
    this.locationCity,
    this.isPremium = false,
    this.hasStore = false,
    this.role = 'user',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
        name: json['name'] ?? '',
        email: json['email'],
        phone: json['phone'],
        bio: json['bio'],
        profilePhoto: json['profilePhoto'],
        locationCity: json['locationCity'],
        isPremium: json['isPremium'] ?? false,
        hasStore: json['hasStore'] ?? false,
        role: json['role'] ?? 'user',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String name;
  final String role;
  final bool isPremium;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.role,
    required this.isPremium,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        userId: json['userId'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'user',
        isPremium: json['isPremium'] ?? false,
      );
}

class AddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final bool isPrimary;

  AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.city,
    required this.province,
    required this.postalCode,
    this.isPrimary = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        label: json['label'] ?? '',
        recipientName: json['recipientName'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        province: json['province'] ?? '',
        postalCode: json['postalCode'] ?? '',
        isPrimary: json['isPrimary'] ?? false,
      );
}
