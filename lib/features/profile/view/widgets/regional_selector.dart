// Location: agrivana\lib\features\profile\view\widgets\regional_selector.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/regional_service.dart';

class UnifiedRegionalSearch extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final void Function(Map<String, dynamic> location) onSelected;

  const UnifiedRegionalSearch({
    super.key,
    required this.label,
    required this.hint,
    required this.onSelected,
    this.initialValue,
  });

  @override
  State<UnifiedRegionalSearch> createState() => _UnifiedRegionalSearchState();
}

class _UnifiedRegionalSearchState extends State<UnifiedRegionalSearch> {
  void _openSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UnifiedSearchSheet(),
    );

    if (result != null) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTap: _openSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.initialValue?.isNotEmpty == true ? widget.initialValue! : widget.hint,
                    style: TextStyle(
                      fontSize: 14, 
                      color: widget.initialValue?.isNotEmpty == true ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.search, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnifiedSearchSheet extends StatefulWidget {
  const _UnifiedSearchSheet();
  @override
  State<_UnifiedSearchSheet> createState() => _UnifiedSearchSheetState();
}

class _UnifiedSearchSheetState extends State<_UnifiedSearchSheet> {
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final res = await RegionalService.searchVillages(query);
        if (mounted) {
          setState(() {
            if (res.success && res.data is List) {
              _results = res.data;
              if (_results.isEmpty) _error = 'Lokasi tidak ditemukan';
            } else {
              _error = res.message.isNotEmpty ? res.message : 'Gagal memuat data';
            }
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Terjadi kesalahan jaringan';
            _loading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cari Wilayah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari Kelurahan / Kecamatan / Kota...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                suffixIcon: _ctrl.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20), 
                        onPressed: () {
                          _ctrl.clear();
                          _onSearchChanged('');
                        }
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ketik minimal 3 huruf untuk mencari nama area pengiriman Anda.',
                style: TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final Map<String, dynamic> item = _results[i];
                          
                          String title = '';
                          if (item['village'] != 'Semua Kelurahan') {
                            title = '${item['village']}, Kecamatan ${item['district']}';
                          } else if (item['district'] != 'Semua Kecamatan') {
                            title = 'Kecamatan ${item['district']}';
                          } else {
                            title = 'Kota/Kab ${item['regency']}';
                          }
                          
                          final String subtitle = '${item['regency']}, ${item['province']}';
                          return ListTile(
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
