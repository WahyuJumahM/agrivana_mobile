//location: agrivana\lib\features\shop\view\product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../utils/formatters.dart';
import '../../../utils/dialogs.dart';
import '../../auth/service/user_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../service/chat_service.dart';
import '../../../services/api_service.dart';
import '../bloc/shop_bloc.dart';
import '../model/product_model.dart';
import 'store_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImage = 0;
  bool _isWished = false;
  bool _wishLoading = false;
  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final productId = args['productId']?.toString();
        if (productId != null) {
          context.read<ProductDetailBloc>().add(ProductDetailLoad(productId));
          _loadReviews(productId);
          _checkWishlistStatus(productId);
        }
        if (args['quantity'] != null) _quantity = args['quantity'] as int;
      }
    });
  }

  Future<void> _checkWishlistStatus(String productId) async {
    final result = await UserService.getWishlist();
    if (result.success && result.data != null) {
      final List items = result.data is List
          ? result.data as List
          : (result.data['items'] ?? []);
      final isWished = items.any((item) {
        if (item is Map) {
          final id = item['productId']?.toString() ?? item['id']?.toString();
          return id == productId;
        }
        return false;
      });
      if (mounted) {
        setState(() => _isWished = isWished);
      }
    }
  }

  void _toggleWishlist(String productId) async {
    if (_wishLoading) return;
    setState(() => _wishLoading = true);
    final result = await UserService.toggleWishlist(productId);
    if (result.success && mounted) {
      setState(() {
        _isWished = !_isWished;
        _wishLoading = false;
      });
      AppDialogs.showSuccess(
        _isWished ? 'Ditambahkan ke wishlist' : 'Dihapus dari wishlist',
      );
    } else {
      if (mounted) setState(() => _wishLoading = false);
    }
  }

  void _chatSeller(ProductModel product) async {
    final ownerId = product.storeOwnerId;
    if (ownerId == null || ownerId.isEmpty) {
      AppDialogs.showError('Penjual tidak ditemukan');
      return;
    }
    AppDialogs.showLoading(message: 'Membuka chat...');
    final result = await ChatService.getOrCreateConversation(ownerId);
    AppDialogs.hideLoading();
    if (result.success && result.data != null && mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.chatConversation,
        arguments: {
          'conversationId': result.data['id']?.toString(),
          'otherUserName': product.storeName ?? 'Penjual',
          'otherUserPhoto': null,
        },
      );
    } else {
      AppDialogs.showError(result.message);
    }
  }

  void _buyNow(ProductModel product) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.id == product.storeOwnerId) {
        AppDialogs.showError(
          'Anda tidak dapat membeli produk dari toko Anda sendiri.',
        );
        return;
      }
    }

    Navigator.of(context).pushNamed(
      AppRoutes.checkout,
      arguments: {'product': product, 'quantity': _quantity},
    );
  }

  Future<void> _loadReviews(String productId) async {
    setState(() => _reviewsLoading = true);
    final result = await ApiService.get(
      '/api/marketplace/products/$productId/reviews',
    );
    if (result.success && result.data != null && mounted) {
      final list = (result.data is List ? result.data as List : [])
          .map((r) => r is Map<String, dynamic> ? r : <String, dynamic>{})
          .toList()
          .cast<Map<String, dynamic>>();
      setState(() {
        _reviews = list;
        _reviewsLoading = false;
      });
    } else {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        actions: [
          BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              if (state is ProductDetailLoaded) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _toggleWishlist(state.product.id),
                    icon: _wishLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isWished ? Icons.favorite : Icons.favorite_border,
                            color: _isWished ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoading) {
            return const ShimmerProductDetail();
          }
          if (state is ProductDetailError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        final args = ModalRoute.of(context)?.settings.arguments;
                        if (args is Map<String, dynamic>) {
                          final pid = args['productId']?.toString();
                          if (pid != null) {
                            context.read<ProductDetailBloc>().add(
                              ProductDetailLoad(pid),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ProductDetailLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is Map<String, dynamic>) {
                  final pid = args['productId']?.toString();
                  if (pid != null) {
                    context.read<ProductDetailBloc>().add(
                      ProductDetailLoad(pid),
                    );
                    await _loadReviews(pid);
                    await _checkWishlistStatus(pid);
                  }
                }
              },
              child: _buildBody(state.product),
            );
          }
          return const Center(child: Text('Memuat...'));
        },
      ),
    );
  }

  Widget _buildBody(ProductModel product) {
    final images = product.allImageUrls;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ─── Product Image Gallery ───────────────────
              Stack(
                children: [
                  if (images.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.85,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentImage = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: MediaQuery.of(context).size.width * 0.85,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_rounded, size: 64, color: Colors.grey),
                      ),
                    ),

                  // Bottom gradient overlay
                  if (images.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Image dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentImage == i ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _currentImage == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: _currentImage == i
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ─── Price & Name Card ────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.1),
                            AppTheme.accent.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        AppFormatters.currency(product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (product.unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'per ${product.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${product.ratingAvg ?? product.rating}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${product.ratingCount ?? 0})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sold
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 14, color: AppTheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                'Terjual ${product.sold}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Stock
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: product.stock > 5
                                ? AppTheme.success.withOpacity(0.08)
                                : AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.stock > 5
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Store Info Card ──────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () {
                      if (product.storeId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StoreProfileScreen(storeId: product.storeId!),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withOpacity(0.1),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                              image:
                                  product.storeImage != null &&
                                      product.storeImage!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(product.storeImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                product.storeImage == null ||
                                    product.storeImage!.isEmpty
                                ? const Icon(
                                    Icons.storefront_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.storeName ?? 'Toko',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (product.storeCity != null &&
                                    product.storeCity!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          product.storeCity!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (product.storeOwnerId != null &&
                              product.storeOwnerId!.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  onTap: () => _chatSeller(product),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_outlined, size: 16, color: AppTheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Chat',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Description Card ─────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_outlined, size: 16, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.description ?? 'Tidak ada deskripsi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Variants Card ────────────────────────────
              if (product.variants.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.style_outlined, size: 16, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Varian',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(product.variants.length, (index) {
                        final v = product.variants[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: index < product.variants.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? AppTheme.background
                                : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  v.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                AppFormatters.currency(v.addPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // ─── Reviews Card ───────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Ulasan Produk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_reviews.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_reviews.length} ulasan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_reviewsLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_reviews.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada ulasan untuk produk ini.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(
                        _reviews.length > 5 ? 5 : _reviews.length,
                        (i) => _buildReviewItem(_reviews[i]),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // space for bottom bar
            ],
          ),
        ),

        // ─── Bottom Bar ────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Quantity
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          onTap: () {
                            if (_quantity > product.minOrder)
                              setState(() => _quantity--);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 18,
                              color: _quantity > product.minOrder
                                  ? AppTheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          onTap: () {
                            if (_quantity < product.stock)
                              setState(() => _quantity++);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: _quantity < product.stock
                                  ? AppTheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Buy button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: product.stock > 0
                          ? AppTheme.primaryGradient
                          : null,
                      color: product.stock > 0 ? null : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: product.stock > 0
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        onTap: product.stock > 0
                            ? () => _buyNow(product)
                            : null,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                product.stock > 0
                                    ? Icons.shopping_cart_rounded
                                    : Icons.remove_shopping_cart_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.stock > 0 ? 'Beli Sekarang' : 'Stok Habis',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment']?.toString();
    final buyerName = review['buyerName']?.toString() ?? 'Pengguna';
    final buyerPhoto = review['buyerPhoto']?.toString();
    final sellerReply = review['sellerReply']?.toString();
    final createdAt = DateTime.tryParse(review['createdAt']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buyer info + rating
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: buyerPhoto != null && buyerPhoto.isNotEmpty
                    ? NetworkImage(buyerPhoto)
                    : null,
                child: buyerPhoto == null || buyerPhoto.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: i < rating ? Colors.amber : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Comment
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
          // Seller reply
          if (sellerReply != null && sellerReply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balasan Penjual',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sellerReply,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
