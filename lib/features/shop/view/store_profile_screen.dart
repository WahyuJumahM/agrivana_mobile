// Location: agrivana\lib\features\shop\view\store_profile_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../services/api_service.dart';
import '../../../utils/formatters.dart';
import 'package:flutter/services.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;

  const StoreProfileScreen({super.key, required this.storeId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  bool _productsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
    _loadProducts();
  }

  Future<void> _loadStoreData() async {
    final res = await ApiService.get('/api/marketplace/stores/${widget.storeId}');
    if (res.success && res.data != null && mounted) {
      setState(() {
        _storeData = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts() async {
    final res = await ApiService.get('/api/marketplace/products?storeId=${widget.storeId}&pageSize=50');
    if (res.success && res.data?['items'] != null && mounted) {
      final list = (res.data!['items'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _products = list;
        _productsLoading = false;
      });
    } else {
      if (mounted) setState(() => _productsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Profil Toko')),
        body: const ShimmerListView(itemCount: 3, itemHeight: 100),
      );
    }

    if (_storeData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Profil Toko')),
        body: const Center(child: Text('Toko tidak ditemukan.')),
      );
    }

    final name = _storeData!['name']?.toString() ?? 'Toko';
    final photo = _storeData!['photoMarket']?.toString();
    final banner = _storeData!['bannerPhoto']?.toString();
    final city = _storeData!['city']?.toString() ?? '-';
    final created = DateTime.tryParse(_storeData!['createdAt']?.toString() ?? '');
    final rating = _storeData!['ratingAvg'] as num? ?? 0.0;
    final totalSales = _storeData!['totalSales'] as int? ?? 0;
    final description = _storeData!['description']?.toString() ?? 'Belum ada deskripsi toko.';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header AppBar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: banner != null && banner.isNotEmpty
                  ? Image.network(banner, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _plBanner())
                  : _plBanner(),
            ),
            backgroundColor: AppTheme.primary,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Store Info Card ──────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.divider, width: 3),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: photo != null && photo.isNotEmpty
                              ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _plPhoto())
                              : _plPhoto(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text(city, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              Text(' ${rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(' • $totalSales Terjual', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Description ─────────────────────────
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deskripsi Toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                      if (created != null) ...[
                        const SizedBox(height: 12),
                        Text('Bergabung: ${created.day}/${created.month}/${created.year}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Products Title ──────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text('Produk Toko Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // ─── Products Grid ─────────────────────────────
          if (_productsLoading)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(24),
              child: ShimmerProductGrid(itemCount: 4),
            ))
          else if (_products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Toko ini belum memiliki produk.', style: TextStyle(color: Colors.grey.shade500)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductCard(_products[index]),
                  childCount: _products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final photo = product['photo']?.toString();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: {'productId': product['id']}),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: AppTheme.softShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: photo != null && photo.isNotEmpty
                  ? Image.network(photo, width: double.infinity, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.2)),
              const SizedBox(height: 4),
              Text(AppFormatters.currency(product['price'] as num? ?? 0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                Text(' ${(product['rating'] as num? ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text('• ${product['sold'] ?? 0} terjual', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _plBanner() => Container(color: AppTheme.primary, child: const Center(child: Icon(Icons.storefront, color: Colors.white24, size: 64)));
  Widget _plPhoto() => Container(color: Colors.grey.shade100, child: const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 32));
}
