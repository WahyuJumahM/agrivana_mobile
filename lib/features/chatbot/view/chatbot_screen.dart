// Location: agrivana\lib\features\chatbot\view\chatbot_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/chatbot_bloc.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _selectedImage = picked);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Ambil dari Kamera',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: Text('Foto langsung dengan kamera',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: Text('Pilih foto yang sudah ada',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    String text = _msgCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    
    // Cegah pengiriman text kosong string "" ke Gemini API saat kirim gambar
    if (text.isEmpty && _selectedImage != null) {
      text = "Tolong analisa gambar ini";
    }

    String? base64Str;
    if (_selectedImage != null) {
      final bytes = await File(_selectedImage!.path).readAsBytes();
      base64Str = base64Encode(bytes);
    }

    if (!mounted) return;
    context
        .read<ChatbotBloc>()
        .add(ChatbotSendMessage(text, imageBase64: base64Str));

    _msgCtrl.clear();
    setState(() => _selectedImage = null);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5), // White/light background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Animated avatar
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50)
                                  .withOpacity(0.3 * _pulseAnimation.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 18)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vana AI',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Online • Asisten Pertanian',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Clear chat button
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20,
                          color: AppTheme.error.withOpacity(0.8)),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Hapus Riwayat',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                            content: const Text(
                                'Hapus semua riwayat percakapan dengan Vana?',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Batal',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5252),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          context.read<ChatbotBloc>().add(ChatbotClearChat());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: BlocBuilder<ChatbotBloc, ChatbotState>(
              builder: (context, state) {
                if (state is ChatbotReady) {
                  if (state.messages.isEmpty) return _buildEmpty();
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount:
                        state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.messages.length) return _buildTyping();
                      final msg = state.messages[i];
                      final isUser = msg['role'] == 'user';
                      return _buildBubble(msg, isUser);
                    },
                  );
                }
                return _buildEmpty();
              },
            ),
          ),
          // Quick reply chips
          BlocBuilder<ChatbotBloc, ChatbotState>(
            builder: (context, state) {
              if (state is ChatbotReady && state.messages.isEmpty) {
                return Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _quickChip('🍅 Cara merawat tomat',
                            'Cara merawat tomat'),
                        _quickChip('🌱 Tips berkebun pemula',
                            'Tips berkebun pemula'),
                        _quickChip('🐛 Hama pada cabai', 'Hama pada cabai'),
                        _quickChip('💧 Jadwal penyiraman',
                            'Jadwal penyiraman yang tepat'),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          // Selected Image Preview
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3)),
                boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_selectedImage!.path),
                        width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gambar terpilih',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text('Tap kirim untuk mengirim',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFFFF5252), size: 16),
                    ),
                  ),
                ],
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Photo button
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8F5E9)),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined,
                          color: AppTheme.primary.withOpacity(0.8), size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8F5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE8F5E9)),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan ke Vana...',
                          hintStyle: TextStyle(
                              color: AppTheme.textHint, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send button
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          size: 18, color: Colors.white),
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

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Futuristic animated orb (green variation)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.15),
                          const Color(0xFF4CAF50).withOpacity(0.02),
                          Colors.transparent,
                        ],
                        radius: _pulseAnimation.value,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF388E3C), Color(0xFF81C784)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                ).createShader(bounds),
                child: const Text(
                  'Halo! Saya Vana',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asisten AI untuk semua kebutuhan\npertanian dan berkebun Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Feature cards
              Row(
                children: [
                  Expanded(
                      child: _featureCard(
                          '🌱', 'Perawatan', 'Tips merawat tanaman')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _featureCard(
                          '🔬', 'Diagnosa', 'Identifikasi masalah')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _featureCard(
                          '📚', 'Edukasi', 'Pelajari teknik baru')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, String> msg, bool isUser) {
    final text = msg['content'] ?? '';
    final base64Image = msg['imageBase64'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFFE8F5E9)),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFF2E7D32).withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Vana AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            if (base64Image != null && base64Image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8F5E9)),
          boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WaveDotsAnimation(controller: _waveController),
            const SizedBox(width: 10),
            const Text(
              'Vana sedang berpikir...',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, String sendText) {
    return GestureDetector(
      onTap: () {
        _msgCtrl.text = sendText;
        _send();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Wave Dots Animation Widget ────────────────────────────────────────
class _WaveDotsAnimation extends StatelessWidget {
  final AnimationController controller;
  const _WaveDotsAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = sin((controller.value * 2 * pi) + (i * pi / 3));
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Transform.translate(
                offset: Offset(0, offset * 3),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
