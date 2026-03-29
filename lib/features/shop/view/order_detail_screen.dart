// Location: agrivana\lib\features\shop\view\order_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../utils/dialogs.dart';
import '../../../services/api_service.dart';
import 'review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final result = await ApiService.get('/api/orders/${widget.orderId}', auth: true);
    if (result.success && result.data != null) {
      setState(() {
        _order = result.data['order'] as Map<String, dynamic>?;
        _items = (result.data['items'] as List?) ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) AppDialogs.showError(result.message);
    }
  }

  Future<void> _dummyPay() async {
    AppDialogs.showLoading(message: 'Memproses pembayaran...');
    final result = await ApiService.post('/api/orders/${widget.orderId}/dummy-pay', auth: true);
    AppDialogs.hideLoading();
    if (result.success) {
      AppDialogs.showSuccess('Pembayaran berhasil dikonfirmasi');
      _loadDetail();
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _confirmReceive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Diterima'),
        content: const Text('Apakah Anda yakin pesanan sudah diterima dengan baik?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Ya, Sudah Diterima'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    AppDialogs.showLoading(message: 'Mengkonfirmasi...');
    final result = await ApiService.post('/api/orders/${widget.orderId}/confirm', auth: true);
    AppDialogs.hideLoading();
    if (result.success) {
      AppDialogs.showSuccess(result.message);
      _loadDetail();
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment': return Colors.orange;
      case 'payment_confirmed': return Colors.blue;
      case 'processing': return Colors.indigo;
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'completed': return AppTheme.success;
      case 'cancelled': return Colors.red;
      case 'refunded': return Colors.deepOrange;
      default: return AppTheme.textHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending_payment': return Icons.hourglass_empty_rounded;
      case 'payment_confirmed': return Icons.check_circle_outline;
      case 'processing': return Icons.inventory_2_outlined;
      case 'shipped': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.markunread_mailbox_outlined;
      case 'completed': return Icons.verified_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      case 'refunded': return Icons.replay_rounded;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Pesanan tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 8),
                      _buildStatusTimeline(),
                      const SizedBox(height: 8),
                      _buildStoreInfo(),
                      const SizedBox(height: 8),
                      _buildItemsList(),
                      const SizedBox(height: 8),
                      _buildAddressCard(),
                      const SizedBox(height: 8),
                      _buildPriceSummary(),
                      if (_buildActionButton() != null) ...[
                        const SizedBox(height: 8),
                        _buildActionButton()!,
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _order!['status']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor(status), _statusColor(status).withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_statusIcon(status), color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppFormatters.orderStatus(status),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('#${_order!['orderNumber'] ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 6),
          Text(AppFormatters.dateFull(DateTime.tryParse(_order!['createdAt']?.toString() ?? '')),
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
        ]),
      ]),
    );
  }

  Widget _buildStatusTimeline() {
    final status = _order!['status']?.toString() ?? '';
    final steps = [
      {'key': 'pending_payment', 'label': 'Menunggu\nBayar', 'icon': Icons.hourglass_empty_rounded},
      {'key': 'payment_confirmed', 'label': 'Dibayar', 'icon': Icons.check_circle_outline},
      {'key': 'processing', 'label': 'Diproses', 'icon': Icons.inventory_2_outlined},
      {'key': 'shipped', 'label': 'Dikirim', 'icon': Icons.local_shipping_outlined},
      {'key': 'completed', 'label': 'Selesai', 'icon': Icons.verified_rounded},
    ];

    if (status == 'cancelled' || status == 'refunded') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(AppFormatters.orderStatus(status),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red)),
        ]),
      );
    }

    final statusOrder = ['pending_payment', 'payment_confirmed', 'processing', 'shipped', 'delivered', 'completed'];
    final currentIdx = statusOrder.indexOf(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final stepKey = steps[i]['key'] as String;
          final stepIdx = statusOrder.indexOf(stepKey);
          final isActive = stepIdx <= currentIdx;
          final isCurrent = stepKey == status || (status == 'delivered' && stepKey == 'completed');
          final color = isActive ? AppTheme.primary : AppTheme.textHint.withOpacity(0.35);

          return Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary.withOpacity(0.15) : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 0 : 1.5),
                ),
                child: Icon(steps[i]['icon'] as IconData, size: 16,
                    color: isCurrent ? Colors.white : color),
              ),
              const SizedBox(height: 6),
              Text(steps[i]['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? AppTheme.textPrimary : AppTheme.textHint)),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildStoreInfo() {
    final trackingNumber = _order!['trackingNumber']?.toString();
    final courier = _order!['courier']?.toString();
    final courierService = _order!['courierService']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_order!['storeName']?.toString() ?? 'Toko',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]),
        if (courier != null && courier.isNotEmpty) ...[
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text('$courier${courierService != null && courierService.isNotEmpty ? ' - $courierService' : ''}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
        ],
        if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.qr_code_rounded, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text('Resi: $trackingNumber',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ]),
        ],
      ]),
    );
  }

  Widget _buildItemsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Daftar Produk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(_items.length, (i) {
          final item = _items[i] as Map<String, dynamic>;
          final photo = item['photo']?.toString();
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo != null && photo.isNotEmpty
                    ? Image.network(photo, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage())
                    : _placeholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['productName']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${item['quantity']} ${item['unit'] ?? 'pcs'} × ${AppFormatters.currency(item['unitPrice'] ?? 0)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ),
              Text(AppFormatters.currency(item['subtotal'] ?? 0),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }

  Widget _buildAddressCard() {
    final address = _order!['address']?.toString();
    final city = _order!['city']?.toString();
    final province = _order!['province']?.toString();
    final recipient = _order!['recipientName']?.toString();
    final phone = _order!['recipientPhone']?.toString();
    final label = _order!['addressLabel']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          const Text('Alamat Pengiriman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        if (recipient != null && recipient.isNotEmpty)
          Text(recipient, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (phone != null && phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
        if (address != null && address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$address${city != null ? ', $city' : ''}${province != null ? ', $province' : ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
      ]),
    );
  }

  Widget _buildPriceSummary() {
    final subtotal = _order!['subtotal'] ?? 0;
    final shipping = _order!['shippingCost'] ?? 0;
    final discount = _order!['discount'] ?? 0;
    final total = _order!['total'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ringkasan Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _priceRow('Subtotal Produk', subtotal),
        const SizedBox(height: 6),
        _priceRow('Ongkos Kirim', shipping),
        if ((discount is num) && discount > 0) ...[
          const SizedBox(height: 6),
          _priceRow('Diskon', discount, isNegative: true),
        ],
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(AppFormatters.currency(total),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ]),
    );
  }

  Widget _priceRow(String label, dynamic amount, {bool isNegative = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      Text('${isNegative ? '-' : ''}${AppFormatters.currency(amount)}',
          style: TextStyle(fontSize: 13, color: isNegative ? AppTheme.success : AppTheme.textPrimary)),
    ]);
  }

  Widget? _buildActionButton() {
    final status = _order!['status']?.toString() ?? '';

    if (status == 'pending_payment') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _dummyPay,
          icon: const Icon(Icons.payment_rounded),
          label: const Text('Bayar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (status == 'shipped' || status == 'delivered') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _confirmReceive,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Konfirmasi Diterima', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (status == 'completed') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Beri Ulasan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Bagikan pengalaman Anda dengan produk ini.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ...List.generate(_items.length, (i) {
              final item = _items[i] as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          orderItemId: item['id']?.toString() ?? '',
                          productName: item['productName']?.toString() ?? '',
                          productImage: item['photo']?.toString(),
                        ),
                      ));
                      if (result == true) _loadDetail();
                    },
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text('Ulas: ${item['productName']?.toString() ?? 'Produk'}',
                        style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    return null;
  }
}
