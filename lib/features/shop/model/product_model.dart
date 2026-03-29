// Location: agrivana\lib\features\shop\model\product_model.dart
class ProductModel {
  final String id;
  final String name;
  final double price;
  final String unit;
  final double rating;
  final int sold;
  final String? storeId;
  final String? storeName;
  final String? storeOwnerId;
  final String? storeCity;
  final String? storeImage;
  final String? city;
  final String? photo;
  final String? image;
  final String? description;
  final int stock;
  final int weightGram;
  final int minOrder;
  final String? category;
  final double? storeRating;
  final int? storeSales;
  final double? ratingAvg;
  final int? ratingCount;
  final String? productImage1;
  final String? productImage2;
  final String? productImage3;
  final List<ProductPhoto> photos;
  final List<ProductVariant> variants;
  final String? storeVillageCode;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.rating = 0,
    this.sold = 0,
    this.storeId,
    this.storeName,
    this.storeOwnerId,
    this.storeCity,
    this.storeImage,
    this.city,
    this.photo,
    this.image,
    this.description,
    this.stock = 0,
    this.weightGram = 0,
    this.minOrder = 1,
    this.category,
    this.storeRating,
    this.storeSales,
    this.ratingAvg,
    this.ratingCount,
    this.productImage1,
    this.productImage2,
    this.productImage3,
    this.photos = const [],
    this.variants = const [],
    this.storeVillageCode,
  });

  /// All available image URLs (from image columns + product_photos table)
  List<String> get allImageUrls {
    final urls = <String>[];
    if (productImage1 != null && productImage1!.isNotEmpty) urls.add(productImage1!);
    if (productImage2 != null && productImage2!.isNotEmpty) urls.add(productImage2!);
    if (productImage3 != null && productImage3!.isNotEmpty) urls.add(productImage3!);
    for (final p in photos) {
      if (!urls.contains(p.url)) urls.add(p.url);
    }
    if (urls.isEmpty && photo != null && photo!.isNotEmpty) urls.add(photo!);
    return urls;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        price: (json['price'] ?? json['basePrice'] ?? 0).toDouble(),
        unit: json['unit'] ?? '',
        rating: (json['rating'] ?? json['ratingAvg'] ?? 0).toDouble(),
        sold: json['sold'] ?? json['totalSold'] ?? 0,
        storeId: json['storeId']?.toString(),
        storeName: json['storeName'],
        storeOwnerId: json['storeOwnerId']?.toString(),
        storeCity: json['storeCity'] ?? json['city'],
        storeImage: json['storeImage']?.toString(),
        city: json['city'],
        photo: json['photo'],
        image: json['productImage1'] ?? json['photo'],
        description: json['description'],
        stock: json['stock'] ?? 0,
        weightGram: json['weightGram'] ?? 0,
        minOrder: json['minOrder'] ?? 1,
        category: json['category'],
        storeRating: json['storeRating']?.toDouble(),
        storeSales: json['storeSales'],
        ratingAvg: (json['ratingAvg'] ?? json['rating'])?.toDouble(),
        ratingCount: json['ratingCount'] ?? json['reviewCount'],
        productImage1: json['productImage1'],
        productImage2: json['productImage2'],
        productImage3: json['productImage3'],
        storeVillageCode: json['storeVillageCode']?.toString(),
      );

  factory ProductModel.fromDetailJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json;
    final photosList = (json['photos'] as List?)
            ?.map((p) => ProductPhoto.fromJson(p))
            .toList() ??
        [];
    final variantsList = (json['variants'] as List?)
            ?.map((v) => ProductVariant.fromJson(v))
            .toList() ??
        [];

    return ProductModel(
      id: product['id']?.toString() ?? '',
      name: product['name'] ?? '',
      price: (product['price'] ?? product['basePrice'] ?? 0).toDouble(),
      unit: product['unit'] ?? '',
      rating: (product['rating'] ?? product['ratingAvg'] ?? 0).toDouble(),
      sold: product['sold'] ?? product['totalSold'] ?? 0,
      storeId: product['storeId']?.toString(),
      storeName: product['storeName'],
      storeOwnerId: product['storeOwnerId']?.toString(),
      storeCity: product['storeCity'] ?? product['city'],
      storeImage: product['storeImage']?.toString(),
      city: product['city'],
      description: product['description'],
      stock: product['stock'] ?? 0,
      weightGram: product['weightGram'] ?? 0,
      minOrder: product['minOrder'] ?? 1,
      category: product['category'],
      storeRating: product['storeRating']?.toDouble(),
      storeSales: product['storeSales'],
      ratingAvg: (product['ratingAvg'] ?? product['rating'])?.toDouble(),
      ratingCount: product['ratingCount'] ?? product['reviewCount'],
      productImage1: product['productImage1'],
      productImage2: product['productImage2'],
      productImage3: product['productImage3'],
      photos: photosList,
      variants: variantsList,
      photo: product['productImage1'] ?? (photosList.isNotEmpty ? photosList.first.url : null),
      image: product['productImage1'] ?? (photosList.isNotEmpty ? photosList.first.url : null),
      storeVillageCode: product['storeVillageCode']?.toString(),
    );
  }
}

class ProductPhoto {
  final String url;
  final bool isPrimary;

  ProductPhoto({required this.url, this.isPrimary = false});

  factory ProductPhoto.fromJson(Map<String, dynamic> json) => ProductPhoto(
        url: json['url'] ?? '',
        isPrimary: json['isPrimary'] ?? false,
      );
}

class ProductVariant {
  final String id;
  final String name;
  final double addPrice;
  final int stock;

  double get price => addPrice;

  ProductVariant({
    required this.id,
    required this.name,
    this.addPrice = 0,
    this.stock = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? json['variantName'] ?? '',
        addPrice: (json['addPrice'] ?? json['additionalPrice'] ?? 0).toDouble(),
        stock: json['stock'] ?? 0,
      );
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        icon: json['icon'],
      );
}
