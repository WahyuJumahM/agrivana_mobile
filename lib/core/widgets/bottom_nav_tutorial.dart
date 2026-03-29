// Location: agrivana\lib\core\widgets\bottom_nav_tutorial.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Data model for each tutorial step.
class _TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Full-screen overlay that guides new users through the bottom nav features.
class BottomNavTutorial extends StatefulWidget {
  final List<GlobalKey> navKeys;
  final VoidCallback onComplete;

  const BottomNavTutorial({
    super.key,
    required this.navKeys,
    required this.onComplete,
  });

  @override
  State<BottomNavTutorial> createState() => _BottomNavTutorialState();
}

class _BottomNavTutorialState extends State<BottomNavTutorial>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      title: 'Beranda',
      description:
          'Halaman utama kamu! Lihat ringkasan kebun, artikel terbaru, dan akses cepat ke semua fitur Agrivana.',
      icon: Icons.home_rounded,
    ),
    _TutorialStep(
      title: 'Toko',
      description:
          'Jelajahi marketplace pertanian — beli bibit, pupuk, alat tani, dan kebutuhan berkebun lainnya.',
      icon: Icons.shopping_bag_rounded,
    ),
    _TutorialStep(
      title: 'Monitor Tanaman',
      description:
          'Kelola dan pantau tanaman kamu! Tambah tanaman baru, catat pertumbuhan, dan dapatkan saran perawatan dari AI.',
      icon: Icons.eco_rounded,
    ),
    _TutorialStep(
      title: 'Edukasi',
      description:
          'Baca artikel dan panduan lengkap seputar pertanian, tips berkebun, dan teknik budidaya terbaru.',
      icon: Icons.menu_book_rounded,
    ),
    _TutorialStep(
      title: 'Profil',
      description:
          'Atur profil, lihat riwayat aktivitas, kelola toko kamu, dan akses pengaturan akun.',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _animController.reset();
      setState(() => _currentStep++);
      _animController.forward();
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  /// Returns the screen-space rect of the nav item at the given step index.
  Rect? _getTargetRect() {
    final key = widget.navKeys[_currentStep];
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final targetRect = _getTargetRect();
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    // Spotlight center & radius
    final spotCenter = targetRect != null
        ? targetRect.center
        : Offset(screen.width / 2, screen.height - 60);
    final spotRadius = targetRect != null
        ? (targetRect.longestSide / 2) + 18
        : 36.0;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ── Dark overlay with spotlight cutout ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (ctx, child) => CustomPaint(
                painter: _SpotlightPainter(
                  center: spotCenter,
                  radius: spotRadius,
                  overlayOpacity: 0.82,
                  pulseValue: _pulseAnim.value,
                ),
              ),
            ),
          ),

          // ── Tooltip Card ──
          AnimatedBuilder(
            animation: _animController,
            builder: (ctx, child) {
              return Positioned(
                bottom: 140,
                left: 24,
                right: 24,
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                ),
              );
            },
            child: _buildTooltipCard(step, isLast, screen),
          ),

          // ── Skip Button (top right) ──
          if (!isLast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (ctx, child) =>
                    Opacity(opacity: _fadeAnim.value, child: child),
                child: TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltipCard(_TutorialStep step, bool isLast, Size screen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(step.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            step.title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Step indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Mulai Sekarang' : 'Lanjut',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                  if (isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),

          // Step counter
          const SizedBox(height: 12),
          Text(
            '${_currentStep + 1} dari ${_steps.length}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a dark overlay with a circular spotlight cutout +
/// a subtle pulsing ring around the spotted item.
class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double overlayOpacity;
  final double pulseValue;

  _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.overlayOpacity,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: overlayOpacity);

    // Create path with spotlight hole
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final spotPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final combinedPath = Path.combine(
      PathOperation.difference,
      outerPath,
      spotPath,
    );
    canvas.drawPath(combinedPath, overlayPaint);

    // Pulse ring
    final pulseRadius = radius + (8 * pulseValue);
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25 * (1 - pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, pulseRadius, ringPaint);

    // Inner glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 4, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.pulseValue != pulseValue;
  }
}
