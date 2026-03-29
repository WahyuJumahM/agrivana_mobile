// Location: agrivana\lib\features\profile\view\seller_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/cloudinary_market_helper.dart';
import '../bloc/profile_bloc.dart';
import '../service/profile_services.dart';
import '../../shop/service/marketplace_service.dart';
import '../../../utils/dialogs.dart';
import 'widgets/regional_selector.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});
  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SellerBloc>().add(SellerLoadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Toko',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<SellerBloc, SellerState>(
        builder: (context, state) {
          if (state is SellerLoading) return const Center(child: CircularProgressIndicator());
          if (state is SellerLoaded) {
            if (state.storeInfo == null) return _buildCreateStore();
            return _buildDashboard(state);
          }
          if (state is SellerError) return Center(child: Text(state.message));
          return const SizedBox();
        },
      ),
    );
  }

  // ─── No Store ─────────────────────────────────────────────
  Widget _buildCreateStore() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 64,
              color: AppTheme.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum punya toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat toko untuk mulai menjual produk',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showCreateStoreSheet(context),
              child: const Text('Buat Toko'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SellerBloc>(),
        child: const _CreateStoreForm(),
      ),
    );
  }

  // ─── Dashboard Menu Grid ──────────────────────────────────
  Widget _buildDashboard(SellerLoaded state) {
    final store = state.storeInfo!;
    final newOrdersCount = state.orders.where((o) => o['status'] == 'payment_confirmed').length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Store Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  image: store['photoMarket'] != null
                      ? DecorationImage(
                          image: NetworkImage(store['photoMarket']),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/images/agrivana-logo.png'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          store['name']?.toString() ?? 'Toko Saya',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Status: Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Total Pendapatan Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pendapatan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.payments_outlined, color: AppTheme.primary.withValues(alpha: 0.7), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_formatNum(store['balance'])}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppTheme.primary, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      '+12.5% bln ini',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesanan Baru',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$newOrdersCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '+5 hari ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Produk Terjual',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${store['totalSales'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '+8% bln ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: AppTheme.primary, width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      text: 'Informasi: Pendapatan yang ditampilkan adalah nilai setelah dipotong biaya layanan platform Agrivana sebesar ',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                      children: [
                        TextSpan(
                          text: '5%.',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Aksi Cepat
          const Text(
            'Aksi Cepat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () => _navigate(context, _ProductsPage(state: state)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Tambah\nProduk', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.2)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: () => _navigate(context, _WithdrawPage(balance: (store['balance'] as num?)?.toDouble() ?? 0)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('Pembayaran', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6. Status Pesanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Pesanan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () => _navigate(context, _OrdersPage(state: state)),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Baru ($newOrdersCount)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 2, color: AppTheme.primary),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Diproses',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.grey.shade200),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Selesai',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.grey.shade200),
                  ],
                ),
              ),
            ],
          ),
          
          if (newOrdersCount > 0) ...[
            const SizedBox(height: 16),
            _buildOrderPreviewCard(state.orders.firstWhere((o) => o['status'] == 'payment_confirmed')),
          ] else ...[
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Belum ada pesanan baru',
                style: TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 32),
          ],
          const SizedBox(height: 24),

          // 7. Kelola Katalog Produk
          GestureDetector(
            onTap: () => _navigate(context, _ProductsPage(state: state)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kelola Katalog Produk',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.products.length} Produk Aktif',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Buka >',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // 8. Menu Lainnya
          const Text(
            'Pengaturan Toko',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _menuCard(
                Icons.store_mall_directory_rounded,
                'Info Toko',
                () => _navigate(context, _StoreInfoPage(state: state)),
              ),
              _menuCard(
                Icons.map_rounded,
                'Lokasi Toko',
                () => _navigate(context, const _StoreLocationPage()),
              ),
              _menuCard(
                Icons.bar_chart_rounded,
                'Laporan',
                () => _navigate(context, const _ReportsPage()),
              ),
              _menuCard(
                Icons.delete_forever_rounded,
                'Hapus Toko',
                () => context.read<SellerBloc>().add(SellerDeleteStore()),
                color: AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderPreviewCard(Map<String, dynamic> o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o['orderNumber']?.toString() ?? 'INV/20231024/001',
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PERLU DIKIRIM',
                  style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            o['buyerName']?.toString() ?? 'Budi Santoso',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textHint, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bibit Cabe Unggul IR64 (5kg)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 Barang x Rp ${o['total'] ?? 75000}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppTheme.textSecondary;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c == AppTheme.textSecondary ? Colors.black87 : c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext ctx, Widget page) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: ctx.read<SellerBloc>(), child: page),
      ),
    );
  }

  String _formatNum(dynamic v) {
    if (v == null) return '0';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. STORE INFO PAGE (Edit Store)
// ═══════════════════════════════════════════════════════════════

class _StoreInfoPage extends StatefulWidget {
  final SellerLoaded state;
  const _StoreInfoPage({required this.state});
  @override
  State<_StoreInfoPage> createState() => _StoreInfoPageState();
}

class _StoreInfoPageState extends State<_StoreInfoPage> {
  late TextEditingController _name,
      _desc,
      _addr,
      _bankName,
      _bankAcc,
      _bankHolder,
      _opDays,
      _opHours;
  String? _photoUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.state.storeInfo!;
    _name = TextEditingController(text: s['name']?.toString() ?? '');
    _desc = TextEditingController(text: s['description']?.toString() ?? '');
    _addr = TextEditingController(text: s['address']?.toString() ?? '');
    _bankName = TextEditingController(text: s['bankName']?.toString() ?? '');
    _bankAcc = TextEditingController(
      text: s['bankAccountNumber']?.toString() ?? '',
    );
    _bankHolder = TextEditingController(
      text: s['bankAccountHolder']?.toString() ?? '',
    );
    _opDays = TextEditingController(
      text: s['operationalDays']?.toString() ?? '',
    );
    _opHours = TextEditingController(
      text: s['operationalHours']?.toString() ?? '',
    );
    _photoUrl = s['photoMarket']?.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _addr.dispose();
    _bankName.dispose();
    _bankAcc.dispose();
    _bankHolder.dispose();
    _opDays.dispose();
    _opHours.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xf = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (xf == null) return;
    setState(() => _uploading = true);
    final url = await CloudinaryHelper.upload(
      xf.path,
      preset: 'profiles_market',
    );
    if (url != null && mounted) setState(() => _photoUrl = url);
    if (mounted) setState(() => _uploading = false);
  }

  void _save() {
    final data = <String, dynamic>{};
    if (_name.text.isNotEmpty) data['name'] = _name.text.trim();
    if (_desc.text.isNotEmpty) data['description'] = _desc.text.trim();
    if (_addr.text.isNotEmpty) data['address'] = _addr.text.trim();
    if (_bankName.text.isNotEmpty) data['bankName'] = _bankName.text.trim();
    if (_bankAcc.text.isNotEmpty)
      data['bankAccountNumber'] = _bankAcc.text.trim();
    if (_bankHolder.text.isNotEmpty)
      data['bankAccountHolder'] = _bankHolder.text.trim();
    if (_opDays.text.isNotEmpty) data['operationalDays'] = _opDays.text.trim();
    if (_opHours.text.isNotEmpty)
      data['operationalHours'] = _opHours.text.trim();
    if (_photoUrl != null) data['photoMarket'] = _photoUrl;
    if (data.isEmpty) return;
    context.read<SellerBloc>().add(SellerUpdateStore(data));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Toko'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo
            GestureDetector(
              onTap: _uploading ? null : _pickPhoto,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  image: _photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _uploading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _photoUrl == null
                    ? const Icon(
                        Icons.add_a_photo_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ketuk untuk ganti foto',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
            const SizedBox(height: 16),
            _field(_name, 'Nama Toko'),
            _field(_desc, 'Deskripsi', lines: 2),
            _field(_addr, 'Alamat', lines: 2),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Info Bank',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            _field(_bankName, 'Nama Bank'),
            _field(_bankAcc, 'Nomor Rekening'),
            _field(_bankHolder, 'Atas Nama'),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Operasional',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            _field(_opDays, 'Hari Operasional', hint: 'Senin - Sabtu'),
            _field(_opHours, 'Jam Operasional', hint: '08:00 - 17:00'),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1.5 STORE LOCATION PAGE (Edit Location)
// ═══════════════════════════════════════════════════════════════

class _StoreLocationPage extends StatefulWidget {
  const _StoreLocationPage();
  @override
  State<_StoreLocationPage> createState() => _StoreLocationPageState();
}

class _StoreLocationPageState extends State<_StoreLocationPage> {
  final _addressCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  String? _provName, _cityName, _distName, _villName, _villId;
  LatLng? _storeLocation;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final result = await SellerService.getStoreLocation();
    if (result.success && result.data != null) {
      final loc = result.data;
      setState(() {
        _addressCtrl.text = loc['address']?.toString() ?? '';
        _provName = loc['province']?.toString();
        _cityName = loc['city']?.toString();
        _distName = loc['district']?.toString();
        _villName = loc['village']?.toString();
        _villId = loc['villageCode']?.toString();
        if (loc['latitude'] != null && loc['longitude'] != null) {
          _storeLocation = LatLng(loc['latitude'], loc['longitude']);
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _StoreMapPickerScreen(initial: _storeLocation),
      ),
    );
    if (result != null) setState(() => _storeLocation = result);
  }

  void _save() {
    if (_addressCtrl.text.isEmpty || (_villId == null && _villName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat detil dan Wilayah wajib diisi'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final data = <String, dynamic>{'address': _addressCtrl.text.trim()};
    if (_provName != null) data['province'] = _provName;
    if (_cityName != null) data['city'] = _cityName;
    if (_villId != null) {
      data['villageCode'] = _villId;
      if (_distName != null) data['district'] = _distName;
      if (_villName != null) data['village'] = _villName;
    }
    if (_storeLocation != null) {
      data['latitude'] = _storeLocation!.latitude;
      data['longitude'] = _storeLocation!.longitude;
    }

    context.read<SellerBloc>().add(SellerUpdateStoreLocation(data));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Lokasi Toko'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Detail *',
                      hintText: 'Jalan, No Rumah, RT/RW',
                    ),
                  ),
                  const SizedBox(height: 16),
                  UnifiedRegionalSearch(
                    label: 'Ubah Wilayah Toko *',
                    hint: 'Cari Kelurahan / Kecamatan / Kota',
                    initialValue: _villName != null
                        ? '$_villName, $_distName'
                        : _cityName,
                    onSelected: (loc) => setState(() {
                      _provName = loc['province'];
                      _cityName = loc['regency'];
                      _distName = loc['district'];
                      _villName = loc['village'];
                      _villId = loc['code'];
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Peta Titik Lokasi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: _storeLocation != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: _storeLocation!,
                                      initialZoom: 15,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag.none,
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.agrivana.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _storeLocation!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.storefront_rounded,
                                              color: AppTheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_storeLocation!.latitude.toStringAsFixed(5)}, ${_storeLocation!.longitude.toStringAsFixed(5)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 28,
                                    color: AppTheme.textHint,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ketuk untuk set titik lokasi toko',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Penting: Menentukan titik lokasi di peta membuat pelanggan lebih mudah menemukan toko, serta membantu perhitungan biaya ongkos kirim.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. PRODUCTS PAGE (List + Add/Edit/Delete)
// ═══════════════════════════════════════════════════════════════

class _ProductsPage extends StatelessWidget {
  final SellerLoaded state;
  const _ProductsPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Produk Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context, null, state.categories),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: BlocBuilder<SellerBloc, SellerState>(
        builder: (context, st) {
          final products = st is SellerLoaded ? st.products : state.products;
          final cats = st is SellerLoaded ? st.categories : state.categories;
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk',
                style: TextStyle(color: AppTheme.textHint),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p['image'] != null
                        ? Image.network(
                            p['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: AppTheme.background,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppTheme.textHint,
                            ),
                          ),
                  ),
                  title: Text(
                    p['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Rp ${p['price'] ?? 0} / ${p['unit'] ?? ''}  •  Stok: ${p['stock'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _fetchAndEdit(context, p, cats);
                      if (v == 'delete')
                        context.read<SellerBloc>().add(
                          SellerDeleteProduct(p['id']?.toString() ?? ''),
                        );
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _fetchAndEdit(BuildContext ctx, Map<String, dynamic> p, List<dynamic> cats) async {
    final id = p['id']?.toString();
    if (id == null) return;
    
    AppDialogs.showLoading(message: 'Memuat data lengkap...');
    final result = await MarketplaceService.getProductById(id);
    AppDialogs.hideLoading();

    if (result.success && result.data != null) {
      final Map<String, dynamic> fullProduct = result.data['product'] ?? result.data;
      if (ctx.mounted) _showProductForm(ctx, fullProduct, cats);
    } else {
      AppDialogs.showError(result.message);
      if (ctx.mounted) _showProductForm(ctx, p, cats); // fallback
    }
  }

  void _showProductForm(
    BuildContext ctx,
    Map<String, dynamic>? product,
    List<dynamic> categories,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<SellerBloc>(),
        child: _ProductForm(product: product, categories: categories),
      ),
    );
  }
}

// product add/edit form
class _ProductForm extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<dynamic> categories;
  const _ProductForm({this.product, required this.categories});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late TextEditingController _name,
      _desc,
      _unit,
      _price,
      _stock,
      _weight,
      _minOrder;
  String? _categoryId;
  String? _img1, _img2, _img3;
  bool _uploading = false;
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name']?.toString() ?? '');
    _desc = TextEditingController(text: p?['description']?.toString() ?? '');
    _unit = TextEditingController(text: p?['unit']?.toString() ?? '');
    _price = TextEditingController(
      text: p?['price']?.toString() ?? p?['basePrice']?.toString() ?? '',
    );
    _stock = TextEditingController(text: p?['stock']?.toString() ?? '');
    _weight = TextEditingController(text: p?['weightGram']?.toString() ?? '');
    _minOrder = TextEditingController(text: p?['minOrder']?.toString() ?? '1');
    _categoryId = p?['categoryId']?.toString();
    _img1 = p?['productImage1']?.toString() ?? p?['image']?.toString();
    _img2 = p?['productImage2']?.toString();
    _img3 = p?['productImage3']?.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _unit.dispose();
    _price.dispose();
    _stock.dispose();
    _weight.dispose();
    _minOrder.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int slot) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null) return;
    final xf = await ImagePicker().pickImage(source: src, maxWidth: 800);
    if (xf == null) return;
    setState(() => _uploading = true);
    final url = await CloudinaryHelper.upload(xf.path, preset: 'products');
    if (url != null && mounted) {
      setState(() {
        if (slot == 1) _img1 = url;
        if (slot == 2) _img2 = url;
        if (slot == 3) _img3 = url;
      });
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _save() {
    if (_name.text.isEmpty || _price.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan harga wajib diisi'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_isEdit) {
      final data = <String, dynamic>{};
      if (_name.text.isNotEmpty) data['name'] = _name.text.trim();
      if (_desc.text.isNotEmpty) data['description'] = _desc.text.trim();
      if (_unit.text.isNotEmpty) data['unit'] = _unit.text.trim();
      if (_price.text.isNotEmpty)
        data['basePrice'] = double.tryParse(_price.text) ?? 0;
      if (_stock.text.isNotEmpty)
        data['stock'] = int.tryParse(_stock.text) ?? 0;
      if (_weight.text.isNotEmpty)
        data['weightGram'] = int.tryParse(_weight.text) ?? 0;
      if (_minOrder.text.isNotEmpty)
        data['minOrder'] = int.tryParse(_minOrder.text) ?? 1;
      if (_categoryId != null) data['categoryId'] = _categoryId;
      if (_img1 != null) data['productImage1'] = _img1;
      if (_img2 != null) data['productImage2'] = _img2;
      if (_img3 != null) data['productImage3'] = _img3;
      context.read<SellerBloc>().add(
        SellerUpdateProduct(widget.product!['id'].toString(), data),
      );
    } else {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih kategori'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final data = {
        'categoryId': _categoryId,
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'unit': _unit.text.trim().isEmpty ? 'kg' : _unit.text.trim(),
        'basePrice': double.tryParse(_price.text) ?? 0,
        'stock': int.tryParse(_stock.text) ?? 0,
        'weightGram': int.tryParse(_weight.text) ?? 0,
        'minOrder': int.tryParse(_minOrder.text) ?? 1,
        if (_img1 != null) 'productImage1': _img1,
        if (_img2 != null) 'productImage2': _img2,
        if (_img3 != null) 'productImage3': _img3,
      };
      context.read<SellerBloc>().add(SellerAddProduct(data));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? 'Edit Produk' : 'Tambah Produk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori *'),
                    items: widget.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _desc,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _unit,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                            hintText: 'kg',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stock,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stok'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weight,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Berat (gram)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minOrder,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Order'),
                  ),
                  const SizedBox(height: 16),
                  // Image upload row
                  const Text(
                    'Foto Produk',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_uploading) const LinearProgressIndicator(),
                  Row(
                    children: [
                      _imgSlot(1, _img1),
                      const SizedBox(width: 8),
                      _imgSlot(2, _img2),
                      const SizedBox(width: 8),
                      _imgSlot(3, _img3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(
                        _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgSlot(int slot, String? url) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(slot),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.divider),
            image: url != null
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: url == null
              ? const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppTheme.textHint,
                )
              : null,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. ORDERS PAGE
// ═══════════════════════════════════════════════════════════════

class _OrdersPage extends StatelessWidget {
  final SellerLoaded state;
  const _OrdersPage({required this.state});

  static const _statuses = [
    {'key': 'payment_confirmed', 'label': 'Baru'},
    {'key': 'processing', 'label': 'Diproses'},
    {'key': 'shipped', 'label': 'Dikirim'},
    {'key': 'completed', 'label': 'Selesai'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pesanan Masuk')),
      body: BlocBuilder<SellerBloc, SellerState>(
        builder: (ctx, st) {
          final selected = st is SellerLoaded
              ? st.selectedStatus
              : 'payment_confirmed';
          final orders = st is SellerLoaded ? st.orders : state.orders;
          return Column(
            children: [
              // Status filter
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: _statuses.map((s) {
                    final active = s['key'] == selected;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s['label']!),
                        selected: active,
                        showCheckmark: false,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: active ? AppTheme.primary : AppTheme.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelStyle: TextStyle(
                          color: active ? Colors.white : AppTheme.textSecondary,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (_) => ctx.read<SellerBloc>().add(
                          SellerSelectStatus(s['key']!),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada pesanan',
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (_, i) =>
                            _orderCard(ctx, orders[i], selected),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext ctx, Map<String, dynamic> o, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o['orderNumber']?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              _statusBadge(o['status']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pembeli: ${o['buyerName'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            'Total: Rp ${o['total'] ?? 0}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Actions
          if (status == 'payment_confirmed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ctx.read<SellerBloc>().add(
                  SellerProcessOrder(o['id']?.toString() ?? ''),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Proses Pesanan'),
              ),
            ),
          if (status == 'processing')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showResiDialog(ctx, o['id']?.toString() ?? ''),
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('Input Resi'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    final map = {
      'payment_confirmed': ('Baru', const Color(0xFF1976D2)), // Blue
      'processing': ('Diproses', const Color(0xFFF57F17)), // Dark Amber/Orange
      'shipped': ('Dikirim', const Color(0xFF00897B)), // Teal
      'completed': ('Selesai', const Color(0xFF2E7D32)), // Green
    };
    final (label, color) = map[s] ?? (s, Colors.grey.shade700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showResiDialog(BuildContext ctx, String orderId) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Input Resi Pengiriman'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nomor Resi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ctx.read<SellerBloc>().add(
                  SellerShipOrder(orderId, ctrl.text.trim()),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. REPORTS PAGE
// ═══════════════════════════════════════════════════════════════

class _ReportsPage extends StatefulWidget {
  const _ReportsPage();
  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  String _period = 'monthly';
  List<dynamic> _revenue = [];
  List<dynamic> _topProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await SellerService.getReportSummary(
      query: {'period': _period},
    );
    if (result.success && result.data != null) {
      setState(() {
        _revenue = result.data['revenue'] is List ? result.data['revenue'] : [];
        _topProducts = result.data['topProducts'] is List
            ? result.data['topProducts']
            : [];
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Laporan Penjualan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Row(
                    children: ['daily', 'weekly', 'monthly']
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                p == 'daily'
                                    ? 'Harian'
                                    : p == 'weekly'
                                    ? 'Mingguan'
                                    : 'Bulanan',
                              ),
                              selected: _period == p,
                              showCheckmark: false,
                              selectedColor: AppTheme.primary,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: _period == p ? AppTheme.primary : AppTheme.divider,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              labelStyle: TextStyle(
                                color: _period == p ? Colors.white : AppTheme.textSecondary,
                                fontWeight: _period == p ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                _period = p;
                                _load();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Revenue list
                  const Text(
                    'Pendapatan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_revenue.isEmpty)
                    const Text(
                      'Belum ada data penjualan',
                      style: TextStyle(color: AppTheme.textHint),
                    )
                  else
                    ..._revenue.map(
                      (r) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['period']?.toString().split('T').first ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${r['orderCount'] ?? 0} pesanan',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${r['netRevenue'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  'Gross: Rp ${r['grossRevenue'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Top products
                  const Text(
                    'Produk Terlaris',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_topProducts.isEmpty)
                    const Text(
                      'Belum ada data',
                      style: TextStyle(color: AppTheme.textHint),
                    )
                  else
                    ..._topProducts.asMap().entries.map((e) {
                      final p = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p['productName']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p['totalQty'] ?? 0} terjual',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Rp ${p['totalRevenue'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. WITHDRAWAL PAGE
// ═══════════════════════════════════════════════════════════════

class _WithdrawPage extends StatefulWidget {
  final double balance;
  const _WithdrawPage({required this.balance});
  @override
  State<_WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<_WithdrawPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Penarikan Saldo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Tersedia',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Rp ${widget.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Penarikan',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(_ctrl.text) ?? 0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan jumlah yang valid'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  context.read<SellerBloc>().add(SellerWithdraw(amt));
                  Navigator.of(context).pop();
                },
                child: const Text('Ajukan Penarikan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE STORE FORM (kept from original)
// ═══════════════════════════════════════════════════════════════

class _CreateStoreForm extends StatefulWidget {
  const _CreateStoreForm();
  @override
  State<_CreateStoreForm> createState() => _CreateStoreFormState();
}

class _CreateStoreFormState extends State<_CreateStoreForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;
  LatLng? _storeLocation;
  String? _photoUrl;
  bool _uploading = false;

  // Regional selection state
  String? _provName;
  String? _cityName;
  String? _distName;
  String? _villId, _villName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xf = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (xf == null) return;
    setState(() => _uploading = true);
    final url = await CloudinaryHelper.upload(
      xf.path,
      preset: 'profiles_market',
    );
    if (url != null && mounted) setState(() => _photoUrl = url);
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty ||
        _villId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, alamat, dan wilayah wajib diisi'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final body = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityName,
      'province': _provName,
      'district': _distName,
      'village': _villName,
      'villageCode': _villId,
      if (_storeLocation != null) 'latitude': _storeLocation!.latitude,
      if (_storeLocation != null) 'longitude': _storeLocation!.longitude,
      if (_photoUrl != null) 'photoMarket': _photoUrl,
    };

    if (mounted) {
      context.read<SellerBloc>().add(SellerCreateStore(body));
      Navigator.of(context).pop();
    }
    if (mounted) setState(() => _saving = false);
  }

  void _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _StoreMapPickerScreen(initial: _storeLocation),
      ),
    );
    if (result != null) setState(() => _storeLocation = result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buat Toko Baru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  Center(
                    child: GestureDetector(
                      onTap: _uploading ? null : _pickPhoto,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          image: _photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _uploading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _photoUrl == null
                            ? const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppTheme.primary,
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Foto Toko (opsional)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Toko *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Toko *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  UnifiedRegionalSearch(
                    label: 'Wilayah Toko *',
                    hint: 'Cari Kelurahan / Kecamatan / Kota',
                    initialValue: _villName != null
                        ? '$_villName, $_distName'
                        : null,
                    onSelected: (loc) => setState(() {
                      _provName = loc['province'];
                      _cityName = loc['regency'];
                      _distName = loc['district'];
                      _villName = loc['village'];
                      _villId = loc['code'];
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lokasi Toko (opsional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: _storeLocation != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: _storeLocation!,
                                      initialZoom: 15,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag.none,
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.agrivana.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _storeLocation!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.storefront_rounded,
                                              color: AppTheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_storeLocation!.latitude.toStringAsFixed(5)}, ${_storeLocation!.longitude.toStringAsFixed(5)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 28,
                                    color: AppTheme.textHint,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ketuk untuk pilih lokasi toko',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Buat Toko'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STORE MAP PICKER (kept from original)
// ═══════════════════════════════════════════════════════════════

class _StoreMapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const _StoreMapPickerScreen({this.initial});
  @override
  State<_StoreMapPickerScreen> createState() => _StoreMapPickerScreenState();
}

class _StoreMapPickerScreenState extends State<_StoreMapPickerScreen> {
  late LatLng _center;
  LatLng? _picked;
  final MapController _mapCtrl = MapController();
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? const LatLng(-6.2088, 106.8456);
    _picked = widget.initial;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi tidak aktif')),
        );
      if (mounted) setState(() => _gettingLocation = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        if (mounted) setState(() => _gettingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen')),
        );
      if (mounted) setState(() => _gettingLocation = false);
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final currentLatLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _picked = currentLatLng;
          _center = currentLatLng;
        });
        _mapCtrl.move(currentLatLng, 15);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan lokasi')),
        );
    }
    if (mounted) setState(() => _gettingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Toko'),
        actions: [
          TextButton(
            onPressed: _picked != null
                ? () => Navigator.of(context).pop(_picked)
                : null,
            child: const Text(
              'Pilih',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: (_, latlng) => setState(() => _picked = latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agrivana.app',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppTheme.primary,
                        size: 46,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'locateStoreMe',
              backgroundColor: Colors.white,
              onPressed: _gettingLocation ? null : _getCurrentLocation,
              child: _gettingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_picked != null)
                    Text(
                      'Lat: ${_picked!.latitude.toStringAsFixed(6)}, Lng: ${_picked!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ketuk peta untuk memilih lokasi toko',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
