// Location: agrivana\lib\features\shop\view\marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../utils/formatters.dart';
import '../bloc/shop_bloc.dart';
import '../model/product_model.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ShopBloc>();
    bloc.add(ShopLoadCategories());
    bloc.add(const ShopLoadProducts());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 20, color: AppTheme.textHint.withValues(alpha: 0.6)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Cari produk...',
                                hintStyle: TextStyle(fontSize: 14, color: AppTheme.textHint.withValues(alpha: 0.6)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onSubmitted: (v) => context.read<ShopBloc>().add(ShopSearch(v)),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                context.read<ShopBloc>().add(const ShopSearch(''));
                              },
                              child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textHint),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.accent.withValues(alpha: 0.08)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            // Categories
            BlocBuilder<ShopBloc, ShopState>(
              buildWhen: (p, c) => c is ShopLoaded || c is ShopLoading,
              builder: (context, state) {
                final categories = state is ShopLoaded ? state.categories : <CategoryModel>[];
                final selectedId = state is ShopLoaded ? state.selectedCategoryId : null;
                return SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _categoryChip('Semua', selectedId == null, () => context.read<ShopBloc>().add(const ShopSelectCategory(null)));
                      }
                      final cat = categories[i - 1];
                      return _categoryChip(cat.name, selectedId == cat.id, () => context.read<ShopBloc>().add(ShopSelectCategory(cat.id)));
                    },
                  ),
                );
              },
            ),
            // Products grid
            Expanded(
              child: BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  if (state is ShopLoading) return const ShimmerProductGrid();
                  if (state is ShopLoaded) {
                    if (state.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.shopping_bag_outlined, size: 40, color: AppTheme.textHint.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tidak ada produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Coba ubah filter atau kata pencarian', style: TextStyle(fontSize: 13, color: AppTheme.textHint.withValues(alpha: 0.7))),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () async {
                        context.read<ShopBloc>().add(const ShopLoadProducts());
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scroll) {
                          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
                            context.read<ShopBloc>().add(ShopLoadMore());
                          }
                          return false;
                        },
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68,
                          ),
                          itemCount: state.products.length,
                          itemBuilder: (_, i) => _ProductCard(product: state.products[i]),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.divider.withValues(alpha: 0.6)),
          boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetail, arguments: {'productId': product.id}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppTheme.radiusLg), topRight: Radius.circular(AppTheme.radiusLg)),
              child: CachedNetworkImage(
                imageUrl: product.photo ?? '',
                height: 120, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 120, color: AppTheme.primarySurface,
                    child: Center(child: Icon(Icons.image_rounded, color: AppTheme.primary.withValues(alpha: 0.3), size: 28))),
                errorWidget: (_, __, ___) => Container(height: 120, color: AppTheme.surfaceVariant,
                    child: Center(child: Icon(Icons.broken_image_outlined, color: AppTheme.textHint.withValues(alpha: 0.4), size: 28))),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.2)),
                    if (product.storeName != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 10, color: AppTheme.textHint.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.storeName!,
                              style: TextStyle(fontSize: 10, color: AppTheme.textHint.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Text(AppFormatters.currency(product.price),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppTheme.warning),
                        const SizedBox(width: 2),
                        Text(product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        if (product.city != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.location_on_outlined, size: 11, color: AppTheme.textHint.withValues(alpha: 0.6)),
                          const SizedBox(width: 2),
                          Expanded(child: Text(product.city!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: AppTheme.textHint.withValues(alpha: 0.6)))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
