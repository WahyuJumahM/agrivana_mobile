// Location: agrivana\lib\utils\formatters.dart
import 'package:intl/intl.dart';

class AppFormatters {
  static String currency(num amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  static String dateShort(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String dateFull(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    return dateShort(date);
  }

  static String orderStatus(String status) {
    switch (status) {
      case 'pending_payment': return 'Menunggu Bayar';
      case 'payment_confirmed': return 'Dibayar';
      case 'processing': return 'Diproses';
      case 'shipped': return 'Dikirim';
      case 'delivered': return 'Tiba';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }

  static String plantPhase(String phase) {
    switch (phase) {
      case 'seedling': return 'Semai';
      case 'rooting': return 'Tumbuh Akar';
      case 'sprout': return 'Bibit';
      case 'vegetative': return 'Vegetatif';
      case 'flowering': return 'Berbunga';
      case 'fruiting': return 'Berbuah';
      case 'harvest': return 'Panen';
      default: return phase;
    }
  }
}
