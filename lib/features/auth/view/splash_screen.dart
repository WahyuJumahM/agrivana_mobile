// Location: agrivana\lib\features\auth\view\splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      bool wasLoggedIn = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        wasLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      } catch (_) {}

      try {
        await ApiService.loadTokens();
      } catch (_) {}

      if (!mounted) return;

      if (wasLoggedIn && ApiService.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Full-screen background image (already has gradient) ───
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_onboarding/splashpage-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. Centered logo ──────────────────────────────────────────
          Align(
            alignment: const Alignment(0, -0.18),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(scale: _scaleAnim, child: child),
                );
              },
              child: SizedBox(
                width: size.width * 0.38,
                height: size.width * 0.38,
                child: Image.asset(
                  'assets/images/splash_onboarding/logo-splash-page.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── 3. Footer tagline ─────────────────────────────────────────
          Positioned(
            bottom: bottomPadding + size.height * 0.032,
            left: size.width * 0.08,
            right: size.width * 0.08,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child,
                  ),
                );
              },
              child: Text(
                'Memperlengkapi masyarakat untuk belajar, bertransaksi, dan berinteraksi.',
                style: GoogleFonts.montserrat(
                  fontSize: size.width * 0.031,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
