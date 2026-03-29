// Location: agrivana\lib\features\shop\view\review_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/dialogs.dart';
import '../../../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final String orderItemId;
  final String productName;
  final String? productImage;

  const ReviewScreen({
    super.key,
    required this.orderItemId,
    required this.productName,
    this.productImage,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      AppDialogs.showError('Pilih rating terlebih dahulu.');
      return;
    }

    setState(() => _submitting = true);
    final result = await ApiService.post(
      '/api/orders/reviews',
      body: {
        'orderItemId': widget.orderItemId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      },
      auth: true,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      AppDialogs.showSuccess(result.message);
      Navigator.pop(context, true); // return true = review submitted
    } else {
      AppDialogs.showError(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Beri Ulasan'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── Product Info ────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.productImage != null && widget.productImage!.isNotEmpty
                    ? Image.network(widget.productImage!, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ─── Rating Stars ───────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Berikan Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 44,
                        color: starValue <= _rating ? Colors.amber : AppTheme.divider,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel(_rating),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ─── Comment ────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Komentar (opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalaman Anda dengan produk ini...',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textHint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ─── Submit Button ──────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Mengirim...' : 'Kirim Ulasan',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: const Icon(Icons.image_outlined, color: AppTheme.textHint, size: 24),
      );

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Sangat Buruk';
      case 2: return 'Buruk';
      case 3: return 'Cukup';
      case 4: return 'Baik';
      case 5: return 'Sangat Baik';
      default: return '';
    }
  }
}
