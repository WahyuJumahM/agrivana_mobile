//location
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/community_bloc.dart';
import '../service/community_service.dart';
import '../../../utils/dialogs.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedChannelId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty || _selectedChannelId == null) {
      AppDialogs.showError('Judul, konten, dan topik harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    List<String> tags = [];
    if (_tagsCtrl.text.isNotEmpty) {
      tags = _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final data = {
      'channelId': _selectedChannelId,
      'title': _titleCtrl.text,
      'body': _bodyCtrl.text,
      'plantTags': tags,
    };

    final result = await CommunityService.createPost(data);
    setState(() => _isLoading = false);

    if (result.success && mounted) {
      AppDialogs.showSuccess('Postingan berhasil dibuat');
      Navigator.of(context).pop(true);
    } else if (mounted) {
      AppDialogs.showError(result.message ?? 'Gagal membuat postingan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Buat Postingan'),
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))))
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _submit,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Topik *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            BlocBuilder<CommunityBloc, CommunityState>(
              builder: (context, state) {
                if (state is CommunityLoaded) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                    ),
                    hint: const Text('Pilih Topik'),
                    value: _selectedChannelId,
                    items: state.channels.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedChannelId = val;
                      });
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 16),
            const Text('Judul *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Masukkan judul postingan',
                border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Konten *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Tuliskan apa yang ingin Anda diskusikan...',
                border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tag Tanaman (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Contoh: cabai, tomat (pisahkan dengan koma)',
                border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Posting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
