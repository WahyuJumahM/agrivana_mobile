// Location: agrivana\lib\features\shop\model\order_model.dart
class OrderModel {
  final String id;
  final String orderNumber;
  final double subtotal;
  final double shippingCost;
  final double total;
  final double? commissionAmt;
  final String status;
  final String? shippingStatus;
  final String? courier;
  final String? courierService;
  final String? trackingNumber;
  final String? notes;
  final DateTime? createdAt;
  final String? storeName;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.subtotal,
    this.shippingCost = 0,
    required this.total,
    this.commissionAmt,
    required this.status,
    this.shippingStatus,
    this.courier,
    this.courierService,
    this.trackingNumber,
    this.notes,
    this.createdAt,
    this.storeName,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id']?.toString() ?? '',
        orderNumber: json['orderNumber'] ?? '',
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        shippingCost: (json['shippingCost'] ?? 0).toDouble(),
        total: (json['total'] ?? 0).toDouble(),
        commissionAmt: json['commissionAmt']?.toDouble(),
        status: json['status'] ?? '',
        shippingStatus: json['shippingStatus'],
        courier: json['courier'],
        courierService: json['courierService'],
        trackingNumber: json['trackingNumber'],
        notes: json['notes'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        storeName: json['storeName'],
      );
}

class OrderItemModel {
  final String? id;
  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemModel({
    this.id,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id']?.toString(),
        productName: json['productName'] ?? '',
        unit: json['unit'] ?? '',
        quantity: json['quantity'] ?? 0,
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        subtotal: (json['subtotal'] ?? 0).toDouble(),
      );
}
