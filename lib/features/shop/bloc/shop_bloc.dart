// Location: agrivana\lib\features\shop\bloc\shop_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/product_model.dart';
import '../service/marketplace_service.dart';
import '../service/order_service.dart';
import '../../../utils/dialogs.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MARKETPLACE BLOC
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// Events
abstract class ShopEvent extends Equatable {
  const ShopEvent();
  @override
  List<Object?> get props => [];
}

class ShopLoadProducts extends ShopEvent {
  final bool reset;
  const ShopLoadProducts({this.reset = true});
  @override
  List<Object?> get props => [reset];
}

class ShopLoadCategories extends ShopEvent {}

class ShopSelectCategory extends ShopEvent {
  final String? categoryId;
  const ShopSelectCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class ShopSearch extends ShopEvent {
  final String query;
  const ShopSearch(this.query);
  @override
  List<Object?> get props => [query];
}

class ShopLoadMore extends ShopEvent {}

// States
abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopLoaded extends ShopState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String searchQuery;
  final int currentPage;
  final int totalPages;

  const ShopLoaded({
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
  });

  ShopLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
  }) {
    return ShopLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    selectedCategoryId,
    searchQuery,
    currentPage,
    totalPages,
  ];
}

// Bloc
class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc() : super(ShopInitial()) {
    on<ShopLoadProducts>(_onLoadProducts);
    on<ShopLoadCategories>(_onLoadCategories);
    on<ShopSelectCategory>(_onSelectCategory);
    on<ShopSearch>(_onSearch);
    on<ShopLoadMore>(_onLoadMore);
  }

  String _searchQuery = '';
  String? _selectedCategoryId;
  int _currentPage = 1;
  int _totalPages = 1;
  List<CategoryModel> _categories = [];

  Future<void> _onLoadCategories(
    ShopLoadCategories event,
    Emitter<ShopState> emit,
  ) async {
    final hardcodedCategories = [
      {
        "id": "a1b2c3d4-0001-4000-8000-000000000001",
        "name": "Bibit & Benih",
        "slug": "bibit-benih"
      },
      {
        "id": "3750d993-a6b4-418a-b90b-49ce0e033d63",
        "name": "Benih & Bibit",
        "slug": "benih-bibit"
      },
      {
        "id": "a1b2c3d4-0002-4000-8000-000000000002",
        "name": "Pupuk",
        "slug": "pupuk"
      },
      {
        "id": "aace13b3-377b-41f9-96cf-1dfecf17b2fd",
        "name": "Pupuk & Media Tanam",
        "slug": "pupuk-media-tanam"
      },
      {
        "id": "a1b2c3d4-0003-4000-8000-000000000003",
        "name": "Alat Pertanian",
        "slug": "alat-pertanian"
      },
      {
        "id": "a1b2c3d4-0004-4000-8000-000000000004",
        "name": "Pestisida",
        "slug": "pestisida"
      },
      {
        "id": "a1b2c3d4-0005-4000-8000-000000000005",
        "name": "Hasil Panen",
        "slug": "hasil-panen"
      },
      {
        "id": "fd24ba78-865e-4e38-ad6b-3a781293e09f",
        "name": "Peralatan Berkebun",
        "slug": "peralatan"
      },
      {
        "id": "0cd7b2b8-fc31-4a8d-aacf-63963cd35891",
        "name": "Produk Olahan",
        "slug": "produk-olahan"
      }
    ];

    _categories = hardcodedCategories
        .map<CategoryModel>((j) => CategoryModel.fromJson(j))
        .toList();
  }

  Future<void> _onLoadProducts(
    ShopLoadProducts event,
    Emitter<ShopState> emit,
  ) async {
    if (event.reset) {
      _currentPage = 1;
    }
    if (event.reset) emit(ShopLoading());

    final query = <String, String>{};
    if (_searchQuery.isNotEmpty) query['search'] = _searchQuery;
    if (_selectedCategoryId != null) query['categoryId'] = _selectedCategoryId!;
    query['sort'] = 'terbaru';
    query['page'] = _currentPage.toString();

    final result = await MarketplaceService.getProducts(query: query);
    if (result.success && result.data != null) {
      final items = result.data['items'] ?? result.data;
      if (items is List) {
        final list = items
            .map<ProductModel>((j) => ProductModel.fromJson(j))
            .toList();
        _totalPages = result.data['totalPages'] ?? 1;

        final currentState = state;
        final existing = (!event.reset && currentState is ShopLoaded)
            ? currentState.products
            : <ProductModel>[];

        emit(
          ShopLoaded(
            products: [...existing, ...list],
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            searchQuery: _searchQuery,
            currentPage: _currentPage,
            totalPages: _totalPages,
          ),
        );
      }
    }
  }

  void _onSelectCategory(ShopSelectCategory event, Emitter<ShopState> emit) {
    _selectedCategoryId = event.categoryId;
    add(const ShopLoadProducts());
  }

  void _onSearch(ShopSearch event, Emitter<ShopState> emit) {
    _searchQuery = event.query;
    add(const ShopLoadProducts());
  }

  void _onLoadMore(ShopLoadMore event, Emitter<ShopState> emit) {
    if (_currentPage < _totalPages) {
      _currentPage++;
      add(const ShopLoadProducts(reset: false));
    }
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PRODUCT DETAIL BLOC
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

class ProductDetailLoad extends ProductDetailEvent {
  final String productId;
  const ProductDetailLoad(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ProductDetailChangeQty extends ProductDetailEvent {
  final int delta;
  const ProductDetailChangeQty(this.delta);
  @override
  List<Object?> get props => [delta];
}

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();
  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final ProductModel product;
  final int quantity;
  const ProductDetailLoaded({required this.product, this.quantity = 1});
  @override
  List<Object?> get props => [product, quantity];
}

class ProductDetailError extends ProductDetailState {
  final String message;
  const ProductDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<ProductDetailLoad>(_onLoad);
    on<ProductDetailChangeQty>(_onChangeQty);
  }

  Future<void> _onLoad(
    ProductDetailLoad event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(ProductDetailLoading());
    try {
      final result = await MarketplaceService.getProductById(event.productId);
      if (result.success && result.data != null) {
        emit(
          ProductDetailLoaded(
            product: ProductModel.fromDetailJson(result.data),
          ),
        );
      } else {
        emit(ProductDetailError(result.message));
      }
    } catch (e, stack) {
      print('=== BLoC EXCEPTION ===\\n\$e\\n\$stack');
      emit(ProductDetailError('System Error: \$e'));
    }
  }

  void _onChangeQty(
    ProductDetailChangeQty event,
    Emitter<ProductDetailState> emit,
  ) {
    final s = state;
    if (s is ProductDetailLoaded) {
      final newQty = s.quantity + event.delta;
      if (newQty >= (s.product.minOrder) && newQty <= s.product.stock) {
        emit(ProductDetailLoaded(product: s.product, quantity: newQty));
      }
    }
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ORDER BLOC
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class OrderLoadList extends OrderEvent {
  final String? status;
  const OrderLoadList({this.status});
  @override
  List<Object?> get props => [status];
}

class OrderCheckout extends OrderEvent {
  final Map<String, dynamic> data;
  const OrderCheckout(this.data);
  @override
  List<Object?> get props => [data];
}

class OrderConfirmReceive extends OrderEvent {
  final String orderId;
  const OrderConfirmReceive(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderListLoaded extends OrderState {
  final List<dynamic> orders;
  const OrderListLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderCheckoutSuccess extends OrderState {}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc() : super(OrderInitial()) {
    on<OrderLoadList>(_onLoad);
    on<OrderCheckout>(_onCheckout);
    on<OrderConfirmReceive>(_onConfirmReceive);
  }

  Future<void> _onLoad(OrderLoadList event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final query = <String, String>{};
    if (event.status != null) query['status'] = event.status!;
    final result = await OrderService.getOrders(
      query: query.isNotEmpty ? query : null,
    );
    if (result.success && result.data != null) {
      final items = result.data is List
          ? result.data
          : (result.data['items'] ?? []);
      emit(OrderListLoaded(items is List ? items : []));
    } else {
      emit(OrderListLoaded(const []));
    }
  }

  Future<void> _onCheckout(
    OrderCheckout event,
    Emitter<OrderState> emit,
  ) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Konfirmasi Pembayaran',
      message: 'Lanjutkan ke pembayaran?',
      confirmText: 'Ya, Bayar',
      icon: Icons.payment_rounded,
    );
    if (!confirmed) return;

    emit(OrderLoading());
    final result = await OrderService.checkout(event.data);

    if (result.success && result.data != null) {
      final invoiceUrl =
          result.data['xendit_invoice_url'] ?? result.data['invoiceUrl'];
      if (invoiceUrl != null) {
        final uri = Uri.parse(invoiceUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      AppDialogs.showSuccess(
        'Pesanan berhasil dibuat. Silakan selesaikan pembayaran.',
      );
      emit(OrderCheckoutSuccess());
    } else {
      AppDialogs.showError(result.message);
      emit(OrderError(result.message));
    }
  }

  Future<void> _onConfirmReceive(
    OrderConfirmReceive event,
    Emitter<OrderState> emit,
  ) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Konfirmasi Penerimaan',
      message: 'Apakah barang sudah diterima?',
      confirmText: 'Ya, Sudah Diterima',
      confirmColor: const Color(0xFF4CAF50),
      icon: Icons.check_circle_outline_rounded,
    );
    if (!confirmed) return;

    emit(OrderLoading());
    final result = await OrderService.confirmReceive(event.orderId);
    if (result.success) {
      AppDialogs.showSuccess('Pesanan dikonfirmasi. Terima kasih!');
      add(const OrderLoadList());
    } else {
      AppDialogs.showError(result.message);
    }
  }
}
