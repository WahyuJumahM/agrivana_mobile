// Location: agrivana\lib\features\shop\view\checkout_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../utils/formatters.dart';
import '../../../utils/dialogs.dart';
import '../../auth/service/user_service.dart';
import '../service/shipping_service.dart';
import '../service/order_service.dart';
import '../model/product_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  ProductModel? _product;
  int _quantity = 1;

  // Address — auto-loaded from primary
  Map<String, dynamic>? _primaryAddress;
  bool _addressLoading = true;
  String? _addressError;

  // Shipping
  List<Map<String, dynamic>> _shippingOptions = [];
  Map<String, dynamic>? _selectedShipping;
  bool _shippingLoading = false;
  String? _shippingError;

  // Payment
  String _paymentMethod = 'qris';
  static const _paymentMethods = [
    {'key': 'qris', 'label': 'QRIS', 'icon': Icons.qr_code_rounded},
    {'key': 'va_bca', 'label': 'VA BCA', 'icon': Icons.account_balance_rounded},
    {'key': 'va_bni', 'label': 'VA BNI', 'icon': Icons.account_balance_rounded},
    {'key': 'va_bri', 'label': 'VA BRI', 'icon': Icons.account_balance_rounded},
    {'key': 'va_mandiri', 'label': 'VA Mandiri', 'icon': Icons.account_balance_rounded},
    {'key': 'gopay', 'label': 'GoPay', 'icon': Icons.wallet_rounded},
    {'key': 'ovo', 'label': 'OVO', 'icon': Icons.wallet_rounded},
    {'key': 'dana', 'label': 'DANA', 'icon': Icons.wallet_rounded},
    {'key': 'shopeepay', 'label': 'ShopeePay', 'icon': Icons.wallet_rounded},
  ];

  // Payment section images mapping
  static const Map<String, String> _paymentImages = {
    'qris': 'assets/images/bank/qris.png',
    'gopay': 'assets/images/bank/gopay.png',
    'ovo': 'assets/images/bank/ovo.png',
    'dana': 'assets/images/bank/dana.png',
    'shopeepay': 'assets/images/bank/spay.png',
    'va_bca': 'assets/images/bank/bcava.png',
    'va_bni': 'assets/images/bank/bniva.png',
    'va_bri': 'assets/images/bank/briva.png',
    'va_mandiri': 'assets/images/bank/mandiriva.png',
  };

  // Expandable section states
  bool _qrisExpanded = true;
  bool _ewalletExpanded = false;
  bool _bankExpanded = false;

  bool _selfPickup = false;
  bool _checkingOut = false;
  final _notesCtrl = TextEditingController();




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _product = args['product'] as ProductModel?;
          _quantity = args['quantity'] as int? ?? 1;
        });
        _loadPrimaryAddressAndShipping();
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Load primary address → then auto-fetch shipping cost
  Future<void> _loadPrimaryAddressAndShipping() async {
    setState(() {
      _addressLoading = true;
      _addressError = null;
    });

    final result = await UserService.getAddresses();
    if (!mounted) return;

    if (result.success && result.data != null) {
      final list = result.data is List ? result.data as List : [];

      // Find primary address
      Map<String, dynamic>? primary;
      for (final a in list) {
        if (a is Map<String, dynamic> && a['isPrimary'] == true) {
          primary = a;
          break;
        }
      }
      // Fallback to first address
      primary ??= list.isNotEmpty ? list.first as Map<String, dynamic> : null;

      if (primary == null) {
        setState(() {
          _addressLoading = false;
          _addressError = 'Belum ada alamat. Silakan tambah alamat di menu Profil terlebih dahulu.';
        });
        return;
      }

      final villageCode = primary['villageCode']?.toString();
      if (villageCode == null || villageCode.isEmpty) {
        setState(() {
          _primaryAddress = primary;
          _addressLoading = false;
          _addressError = 'Alamat utama belum memiliki kode wilayah (village code). Perbarui alamat Anda di menu Profil.';
        });
        return;
      }

      setState(() {
        _primaryAddress = primary;
        _addressLoading = false;
      });

      // Auto-fetch shipping cost
      _fetchShippingCost();
    } else {
      setState(() {
        _addressLoading = false;
        _addressError = 'Gagal memuat alamat: ${result.message}';
      });
    }
  }

  /// Fetch shipping cost — calls api.co.id DIRECTLY, auto-selects JNE
  Future<void> _fetchShippingCost() async {
    if (_product == null || _primaryAddress == null) return;

    final destVillageCode = _primaryAddress!['villageCode']?.toString();
    if (destVillageCode == null || destVillageCode.isEmpty) {
      setState(() => _shippingError = 'Alamat belum memiliki kode wilayah.');
      return;
    }

    final originVillageCode = _product!.storeVillageCode;
    if (originVillageCode == null || originVillageCode.isEmpty) {
      setState(() => _shippingError = 'Toko belum memiliki kode wilayah.');
      return;
    }

    setState(() {
      _shippingLoading = true;
      _shippingError = null;
      _shippingOptions = [];
      _selectedShipping = null;
    });

    // Calculate total weight: product weightGram * qty, convert to kg (min 1 kg)
    final totalWeightKg = (_product!.weightGram * _quantity) / 1000.0;
    final weight = totalWeightKg > 0 ? totalWeightKg : 1.0;

    // Call api.co.id DIRECTLY (not via backend proxy)
    final result = await ShippingService.getShippingCost(
      originVillageCode: originVillageCode,
      destinationVillageCode: destVillageCode,
      weightKg: weight,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final jneOption = _findJneOption(result.data, weight);
      setState(() {
        _shippingLoading = false;
        if (jneOption != null) {
          _selectedShipping = jneOption;
          _shippingOptions = [jneOption];
        } else {
          _shippingError = 'Kurir JNE tidak tersedia untuk rute ini.';
        }
      });
    } else {
      setState(() {
        _shippingLoading = false;
        _shippingError = result.message.isNotEmpty ? result.message : 'Gagal menghitung ongkir.';
      });
    }
  }

  /// Find JNE (or JNE Cargo if >=10kg) from api.co.id response
  Map<String, dynamic>? _findJneOption(dynamic data, double weightKg) {
    final useCargo = weightKg >= 10;
    final targetCode = useCargo ? 'jnecargo' : 'jne';

    try {
      // data from ShippingService.getShippingCost is the 'data' field of api.co.id response:
      // { origin_village_code, destination_village_code, weight, couriers: [...] }
      List<dynamic> couriers = [];

      if (data is Map && data['couriers'] is List) {
        couriers = data['couriers'];
      } else if (data is List) {
        couriers = data;
      }

      for (final courier in couriers) {
        if (courier is! Map) continue;
        final code = (courier['courier_code'] ?? '').toString().toLowerCase();
        if (code != targetCode) continue;

        final price = courier['price'] ?? 0;
        final priceNum = price is num ? price : (num.tryParse(price.toString()) ?? 0);
        if (priceNum <= 0) continue;

        return {
          'courier': (courier['courier_name'] ?? 'JNE').toString(),
          'service': code.toUpperCase(),
          'cost': priceNum.toInt(),
          'etd': courier['estimation']?.toString() ?? '-',
        };
      }
    } catch (e) {
      debugPrint('Shipping parse error: $e');
    }
    return null;
  }

  double get _subtotal => (_product?.price ?? 0) * _quantity;
  double get _shippingCost => _selfPickup ? 0 : ((_selectedShipping?['cost'] as num?)?.toDouble() ?? 0);
  double get _total => _subtotal + _shippingCost;

  Future<void> _onRefresh() async {
    await _loadPrimaryAddressAndShipping();
  }

  Future<void> _doCheckout() async {
    if (_product == null) return;
    if (_primaryAddress == null) {
      AppDialogs.showError('Belum ada alamat pengiriman. Tambahkan di menu Profil.');
      return;
    }
    if (_selectedShipping == null) {
      AppDialogs.showError('Ongkos kirim belum dihitung. Pastikan alamat sudah diisi.');
      return;
    }

    final pm = _paymentMethods.firstWhere((m) => m['key'] == _paymentMethod);
    final confirm = await AppDialogs.showConfirmDialog(
      title: 'Konfirmasi Pembayaran',
      message: 'Total: ${AppFormatters.currency(_total)}\nMetode: ${pm['label']}\n\nLanjutkan pembayaran?',
      confirmText: 'Bayar',
      icon: Icons.payment_rounded,
    );
    if (!confirm) return;

    setState(() => _checkingOut = true);

    final data = <String, dynamic>{
      'storeId': _product!.storeId,
      'addressId': _primaryAddress!['id']?.toString(),
      'items': [
        {
          'productId': _product!.id,
          'productName': _product!.name,
          'unit': _product!.unit,
          'quantity': _quantity,
          'unitPrice': _product!.price,
        }
      ],
      'subtotal': _subtotal,
      'shippingCost': _shippingCost,
      'courier': _selfPickup ? 'Ambil Sendiri' : _selectedShipping?['courier'],
      'courierService': _selfPickup ? 'PICKUP' : _selectedShipping?['service'],
      'paymentMethod': _paymentMethod,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    final result = await OrderService.checkout(data);
    if (!mounted) return;
    setState(() => _checkingOut = false);

    if (result.success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Pembayaran Berhasil!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(result.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.orderList,
                      (route) => route.settings.name == AppRoutes.main,
                    );
                  },
                  child: const Text('Lihat Pesanan'),
                ),
              ),
            ]),
          ),
        ),
      );
    } else {
      AppDialogs.showError(result.message);
    }
  }

  // Auto-expand section when a payment method is selected
  void _selectPayment(String key) {
    setState(() {
      _paymentMethod = key;
      // Auto-expand the relevant section
      if (key == 'qris') {
        _qrisExpanded = true;
      } else if (['gopay', 'ovo', 'dana', 'shopeepay'].contains(key)) {
        _ewalletExpanded = true;
      } else {
        _bankExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: _product == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(children: [
                  const SizedBox(height: 8),

                  // ─── Product Summary ──────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: _product!.image != null
                            ? Image.network(_product!.image!, width: 72, height: 72, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imagePlaceholder())
                            : _imagePlaceholder(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_product!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(AppFormatters.currency(_product!.price),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('x$_quantity', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ─── Address (auto primary) ───────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Alamat Pengiriman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        if (_primaryAddress != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_primaryAddress!['label']?.toString() ?? 'Utama',
                                style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      if (_addressLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                      else if (_addressError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_addressError!, style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).pushNamed(AppRoutes.addresses);
                                _loadPrimaryAddressAndShipping();
                              },
                              child: const Text('→ Kelola Alamat',
                                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        )
                      else if (_primaryAddress != null) ...[
                        Text(_primaryAddress!['recipientName']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(_primaryAddress!['phone']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Text(_primaryAddress!['address']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                        Text(
                          [_primaryAddress!['village'], _primaryAddress!['district'],
                           _primaryAddress!['city'], _primaryAddress!['province']]
                              .where((e) => e != null && e.toString().isNotEmpty)
                              .join(', '),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ─── Shipping ─────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, size: 16, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text('Pengiriman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),

                      // ─── Self Pickup Option ────────────
                      GestureDetector(
                        onTap: () => setState(() => _selfPickup = !_selfPickup),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: _selfPickup
                                ? LinearGradient(colors: [
                                    AppTheme.success.withOpacity(0.08),
                                    AppTheme.success.withOpacity(0.03),
                                  ])
                                : null,
                            color: _selfPickup ? null : AppTheme.background,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: _selfPickup ? AppTheme.success.withOpacity(0.5) : AppTheme.divider,
                              width: _selfPickup ? 1.5 : 1,
                            ),
                          ),
                          child: Row(children: [
                            SizedBox(
                              width: 22, height: 22,
                              child: Checkbox(
                                value: _selfPickup,
                                onChanged: (v) => setState(() => _selfPickup = v ?? false),
                                activeColor: AppTheme.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _selfPickup
                                    ? AppTheme.success.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.store_rounded,
                                size: 16,
                                color: _selfPickup ? AppTheme.success : AppTheme.textHint,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambil di Toko',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selfPickup ? AppTheme.success : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ambil pesanan langsung ke toko untuk gratis ongkir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _selfPickup ? AppTheme.success.withOpacity(0.7) : AppTheme.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selfPickup)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'GRATIS',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.success),
                                ),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ─── Courier Shipping Info ─────────
                      if (!_selfPickup) ...[
                        if (_shippingLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        else if (_shippingError != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_shippingError!, style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _fetchShippingCost,
                                child: const Text('↻ Coba Lagi',
                                    style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          )
                        else if (_shippingOptions.isEmpty)
                          const Text('Menunggu data alamat...', style: TextStyle(fontSize: 12, color: AppTheme.textHint))
                        else if (_selectedShipping != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withOpacity(0.06),
                                  AppTheme.accent.withOpacity(0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_shipping_rounded, size: 18, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${_selectedShipping!['courier']}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  if ((_selectedShipping!['etd'] as String?)?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text('Estimasi: ${_selectedShipping!['etd']}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                    ),
                                ]),
                              ),
                              Text(AppFormatters.currency(_selectedShipping!['cost']),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                            ]),
                          )
                        else
                          const Text('Menunggu data alamat...', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                      ] else
                        // Self pickup selected - show friendly message
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.store_rounded, size: 18, color: AppTheme.success),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Ambil Sendiri di Toko',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.success)),
                                SizedBox(height: 2),
                                Text('Ongkos kirim tidak dikenakan',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                              ]),
                            ),
                            const Text('Rp 0',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.success)),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ─── Payment Method (Radio + Sections) ───────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.payment_rounded, size: 16, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text('Metode Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 16),

                      // QRIS Section
                      _buildPaymentSection(
                        title: 'QRIS',
                        icon: Icons.qr_code_rounded,
                        isExpanded: _qrisExpanded,
                        onToggle: () => setState(() => _qrisExpanded = !_qrisExpanded),
                        methods: _paymentMethods.where((m) => m['key'] == 'qris').toList(),
                      ),
                      const SizedBox(height: 10),

                      // E-Wallet Section
                      _buildPaymentSection(
                        title: 'E-Wallet',
                        icon: Icons.wallet_rounded,
                        isExpanded: _ewalletExpanded,
                        onToggle: () => setState(() => _ewalletExpanded = !_ewalletExpanded),
                        methods: _paymentMethods.where((m) => ['gopay', 'ovo', 'dana', 'shopeepay'].contains(m['key'])).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Bank Transfer Section
                      _buildPaymentSection(
                        title: 'Bank Transfer (VA)',
                        icon: Icons.account_balance_rounded,
                        isExpanded: _bankExpanded,
                        onToggle: () => setState(() => _bankExpanded = !_bankExpanded),
                        methods: _paymentMethods.where((m) => ['va_bca', 'va_bni', 'va_bri', 'va_mandiri'].contains(m['key'])).toList(),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ─── Notes ────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
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
                            child: const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 10),
                          const Text('Catatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Pesan untuk penjual... (opsional)',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Voucher ────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        onTap: () => AppDialogs.showError('Fitur voucher masih belum tersedia.'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primary.withOpacity(0.15),
                                    AppTheme.accent.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_offer_outlined, size: 20, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text('Pakai Voucher', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

      // ─── Bottom Summary & Pay Button ──────
      bottomNavigationBar: _product == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(AppFormatters.currency(_subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Ongkir', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    if (_selfPickup) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Ambil di Toko', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.success)),
                      ),
                    ],
                  ]),
                  Text(
                    _selfPickup ? 'GRATIS' : (_shippingCost > 0 ? AppFormatters.currency(_shippingCost) : '-'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selfPickup ? FontWeight.w700 : FontWeight.w500,
                      color: _selfPickup ? AppTheme.success : null,
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppTheme.divider),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(AppFormatters.currency(_total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: !_checkingOut ? AppTheme.primaryGradient : null,
                    color: _checkingOut ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: !_checkingOut
                        ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: _checkingOut ? null : _doCheckout,
                      child: Center(
                        child: _checkingOut
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Bayar Sekarang',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  // ─── Payment Section Builder ─────────────────────────
  Widget _buildPaymentSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Map<String, dynamic>> methods,
  }) {
    final hasSelected = methods.any((m) => m['key'] == _paymentMethod);

    return Container(
      decoration: BoxDecoration(
        color: hasSelected ? AppTheme.primary.withOpacity(0.03) : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: hasSelected ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider.withOpacity(0.6),
          width: hasSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: hasSelected ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (hasSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Dipilih',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hasSelected ? AppTheme.primary : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Payment items
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: AppTheme.divider.withOpacity(0.4)),
                ...methods.map((m) => _buildPaymentRadioItem(m)),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // ─── Individual Payment Radio Item ─────────────────────
  Widget _buildPaymentRadioItem(Map<String, dynamic> method) {
    final key = method['key'] as String;
    final label = method['label'] as String;
    final isSelected = _paymentMethod == key;
    final imagePath = _paymentImages[key];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectPayment(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.04) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.divider,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Payment image
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.image_outlined, size: 16, color: AppTheme.textHint),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
              ),
              // Checkmark when selected
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.image_outlined, color: AppTheme.textHint),
      );
}
