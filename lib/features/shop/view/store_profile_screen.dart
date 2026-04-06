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
        appBar: AppBar(
          title: const Text('Profil Toko'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const ShimmerListView(itemCount: 3, itemHeight: 100),
      );
    }

    if (_storeData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Profil Toko'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
            expandedHeight: 200,
            pinned: true,
            title: const Text('Profil Toko'),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  banner != null && banner.isNotEmpty
                      ? Image.network(banner, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _plBanner())
                      : _plBanner(),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppTheme.primary,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Store Info Card (with overlapping avatar) ──────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store name
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Location
                          Row(children: [
                            Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(child: Text(city, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                          ]),
                          const SizedBox(height: 12),
                          // Stats row
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text('Rating', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ]),
                                ),
                                Container(width: 1, height: 30, color: AppTheme.divider),
                                Expanded(
                                  child: Column(children: [
                                    Text('$totalSales', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Terjual', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ]),
                                ),
                                Container(width: 1, height: 30, color: AppTheme.divider),
                                Expanded(
                                  child: Column(children: [
                                    Text('${_products.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Produk', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                          if (created != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text('Bergabung sejak ${created.day}/${created.month}/${created.year}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    // Floating avatar
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: photo != null && photo.isNotEmpty
                                ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _plPhoto())
                                : _plPhoto(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Description Card ─────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text('Deskripsi Toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Products Title ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Produk Toko Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${_products.length} produk', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ),
                const SizedBox(height: 12),
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
                  padding: const EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Toko ini belum memiliki produk.', style: TextStyle(color: Colors.grey.shade500)),
                  ]),
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
