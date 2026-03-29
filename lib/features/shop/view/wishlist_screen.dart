// Location: agrivana\lib\features\shop\view\wishlist_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../utils/formatters.dart';
import '../../../utils/dialogs.dart';
import '../../auth/service/user_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await UserService.getWishlist();
    if (result.success && result.data != null) {
      _items = result.data is List ? result.data : [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removeItem(String productId) async {
    final result = await UserService.toggleWishlist(productId);
    if (result.success) {
      AppDialogs.showSuccess('Dihapus dari wishlist');
      _load();
    } else {
      AppDialogs.showError(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Wishlist')),
      body: _loading
          ? const ShimmerListView(itemCount: 5, itemHeight: 90)
          : _items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.primarySurface, shape: BoxShape.circle),
                      child: Icon(Icons.favorite_outline, size: 40, color: AppTheme.textHint.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Wishlist kosong', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
                    const SizedBox(height: 8),
                    const Text('Simpan produk favoritmu di sini',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i] as Map<String, dynamic>;
                      final productId = item['productId']?.toString() ?? item['id']?.toString() ?? '';
                      final imageUrl = item['productImage1']?.toString() ?? item['photo']?.toString();
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.productDetail,
                          arguments: {'productId': productId},
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(children: [
                            // Product image
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              child: imageUrl != null
                                  ? Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _placeholder())
                                  : _placeholder(),
                            ),
                            const SizedBox(width: 12),
                            // Product info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['name']?.toString() ?? 'Produk',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(AppFormatters.currency(item['price'] ?? item['basePrice'] ?? 0),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                  const SizedBox(height: 4),
                                  if (item['storeName'] != null)
                                    Text(item['storeName'].toString(),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                ]),
                              ),
                            ),
                            // Remove button
                            IconButton(
                              onPressed: () => _removeItem(productId),
                              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                            ),
                            const SizedBox(width: 4),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _placeholder() => Container(
        width: 90, height: 90, color: AppTheme.background,
        child: const Icon(Icons.image_outlined, color: AppTheme.textHint),
      );
}
