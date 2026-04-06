// Location: agrivana\lib\features\shop\view\order_list_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../utils/formatters.dart';
import '../../../utils/dialogs.dart';
import '../../../services/api_service.dart';
import '../service/order_service.dart';
import 'order_detail_screen.dart';
import 'review_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _activeFilter;

  static const _tabs = [
    {'key': null, 'label': 'Semua'},
    {'key': 'pending_payment', 'label': 'Belum Bayar'},
    {'key': 'payment_confirmed', 'label': 'Dikonfirmasi'},
    {'key': 'processing', 'label': 'Diproses'},
    {'key': 'shipped', 'label': 'Dikirim'},
    {'key': 'completed', 'label': 'Selesai'},
    {'key': 'cancelled', 'label': 'Dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _activeFilter = _tabs[_tabCtrl.index]['key'];
        _loadOrders();
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final query = <String, String>{};
    if (_activeFilter != null) query['status'] = _activeFilter!;
    final result = await OrderService.getOrders(query: query.isEmpty ? null : query);
    if (result.success && result.data != null && mounted) {
      setState(() {
        _orders = result.data is List ? result.data : [];
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReceive(String orderId) async {
    final confirm = await AppDialogs.showConfirmDialog(
      title: 'Konfirmasi Penerimaan',
      message: 'Pastikan barang sudah diterima dengan baik. Dana akan diteruskan ke penjual.',
      confirmText: 'Ya, Terima',
      icon: Icons.check_circle_outline,
      confirmColor: AppTheme.success,
    );
    if (!confirm) return;

    AppDialogs.showLoading(message: 'Mengkonfirmasi...');
    final result = await OrderService.confirmReceive(orderId);
    AppDialogs.hideLoading();

    if (result.success) {
      AppDialogs.showSuccess(result.message);
      _loadOrders();
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment': return Colors.orange;
      case 'payment_confirmed': return Colors.blue;
      case 'processing': return Colors.indigo;
      case 'shipped': return AppTheme.primary;
      case 'delivered': return AppTheme.success;
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.textHint;
    }
  }

  /// Parse estimation like "1 - 2 days" or "1-2" and return estimated arrival date string
  String _estimatedArrival(Map<String, dynamic> order) {
    final estimation = order['courierEstimation']?.toString() ?? order['etd']?.toString() ?? '';
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    if (createdAt == null) return '';

    // Extract max days from estimation like "1-2", "1 - 2 days", "2-3 hari"
    final regex = RegExp(r'(\d+)\s*[-–]\s*(\d+)');
    final match = regex.firstMatch(estimation);
    int maxDays = 3; // default
    if (match != null) {
      maxDays = int.tryParse(match.group(2) ?? '') ?? 3;
    } else {
      final singleDay = RegExp(r'(\d+)').firstMatch(estimation);
      if (singleDay != null) maxDays = int.tryParse(singleDay.group(1) ?? '') ?? 3;
    }

    // Use WIB timezone (UTC+7)
    final createdWib = createdAt.toUtc().add(const Duration(hours: 7));
    final arrivalDate = createdWib.add(Duration(days: maxDays));
    return AppFormatters.dateShort(arrivalDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: _loading
          ? const ShimmerListView(itemCount: 5, itemHeight: 120)
          : _orders.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.primarySurface, shape: BoxShape.circle),
                      child: Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textHint.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Belum ada pesanan', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final order = _orders[i] as Map<String, dynamic>;
                      final status = order['status']?.toString() ?? '';
                      final canConfirm = status == 'shipped' || status == 'delivered';
                      final arrivalEstimate = _estimatedArrival(order);
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderId: order['id']?.toString() ?? ''),
                          ));
                          _loadOrders(); // Refresh on return
                        },
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Header
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(
                              child: Row(children: [
                                const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(order['storeName']?.toString() ?? 'Toko',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(AppFormatters.orderStatus(status),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _statusColor(status))),
                            ),
                          ]),
                          const Divider(height: 20),

                          // Order info
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('#${order['orderNumber'] ?? order['id'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                            if (order['createdAt'] != null)
                              Text(AppFormatters.dateShort(DateTime.tryParse(order['createdAt'].toString())),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                          ]),
                          const SizedBox(height: 8),

                          // Courier & Estimated Arrival
                          if (order['courier'] != null && order['courier'].toString().isNotEmpty) ...[
                            Row(children: [
                              const Icon(Icons.local_shipping_outlined, size: 14, color: AppTheme.textHint),
                              const SizedBox(width: 6),
                              Text(order['courier']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              if (arrivalEstimate.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                                Text('Est. tiba: $arrivalEstimate',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                              ],
                            ]),
                            const SizedBox(height: 8),
                          ],

                          // Tracking number
                          if (order['trackingNumber'] != null && order['trackingNumber'].toString().isNotEmpty) ...[
                            Row(children: [
                              const Icon(Icons.qr_code_rounded, size: 14, color: AppTheme.textHint),
                              const SizedBox(width: 6),
                              Text('Resi: ${order['trackingNumber']}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 8),
                          ],

                          // Total
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Total', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            Text(AppFormatters.currency(order['total'] ?? 0),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                          ]),

                          // Action buttons
                          if (status == 'pending_payment') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  AppDialogs.showLoading(message: 'Memproses pembayaran...');
                                  // Create a dummy endpoint call to set status to payment_confirmed
                                  final result = await ApiService.post('/api/orders/${order['id']}/dummy-pay', auth: true);
                                  AppDialogs.hideLoading();
                                  if (result.success) {
                                    AppDialogs.showSuccess('Pembayaran berhasil dikonfirmasi');
                                    _loadOrders();
                                  } else {
                                    AppDialogs.showError(result.message);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                child: const Text('Bayar Sekarang'),
                              ),
                            ),
                          ],
                          if (canConfirm) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _confirmReceive(order['id']?.toString() ?? ''),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                child: const Text('Konfirmasi Diterima'),
                              ),
                            ),
                          ],
                          if (status == 'completed') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  // Navigate to order detail to see review options for each item
                                  await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(orderId: order['id']?.toString() ?? ''),
                                  ));
                                  _loadOrders();
                                },
                                icon: const Icon(Icons.rate_review_outlined, size: 18),
                                label: const Text('Beri Ulasan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ]),
                      ),
                      );
                    },
                  ),
                ),
    );
  }
}
