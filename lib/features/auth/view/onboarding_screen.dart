// Location: agrivana\lib\features\auth\view\onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  final _slides = const [
    _SlideData(
      title: 'Belajar bagaimana\nmembangun\nkebunmu sendiri.',
      desc:
          'Pelajari langkah tepat budidaya modern dengan panduan interaktif yang dipersonalisasi khusus untuk Anda',
      image: 'assets/images/splash_onboarding/onboarding1.png',
    ),
    _SlideData(
      title: 'Belajar bagaimana\nberpenghasilan dari\nhasil kebunmu.',
      desc:
          'Gunakan teknologi untuk deteksi diri serta pantau setiap fase tumbuh tanaman.',
      image: 'assets/images/splash_onboarding/onboarding2.png',
    ),
    _SlideData(
      title: 'Belajar bagaimana\nmembantu sesama\ndalam kebaikan.',
      desc:
          'Wujudkan kepedulian sosial dengan mendukung pemenuhan pangan lokal dan berbagi kebaikan melalui hasil bumi yang sehat.',
      image: 'assets/images/splash_onboarding/onboarding3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    final bottomPadding = mq.padding.bottom;

    // Responsive base unit (designed for ~375w screen)
    final double scale = screenWidth / 375;
    final imageHeight = screenHeight * 0.58;

    // Responsive sizes
    final double cardRadius = 32 * scale;
    final double cardPadH = 28 * scale;
    final double cardPadTop = 36 * scale;
    final double cardPadBottom = 24 * scale;
    final double titleSize = (24 * scale).clamp(18.0, 30.0);
    final double descSize = (13 * scale).clamp(11.0, 17.0);
    final double welcomeSize = (18 * scale).clamp(14.0, 22.0);
    final double logoSize = (48 * scale).clamp(36.0, 60.0);
    final double dotActiveW = 24 * scale;
    final double dotInactiveW = 8 * scale;
    final double dotH = 8 * scale;
    final double btnImgSize = (56 * scale).clamp(44.0, 68.0);
    final double lewatiPadH = 24 * scale;
    final double lewatiPadV = 12 * scale;
    final double lewatiFontSize = (14 * scale).clamp(12.0, 18.0);
    final double bottomOffset = (40 * scale) + bottomPadding * 0.5;
    final double sideInset = 28 * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── PageView (image full-width + white card overlapping) ──
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) {
              final slide = _slides[i];
              return Stack(
                children: [
                  // Background image — fills top portion
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight,
                    child: Image.asset(slide.image, fit: BoxFit.cover),
                  ),

                  // White card that overlaps onto the image
                  Positioned(
                    top: imageHeight - cardRadius,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(cardRadius),
                          topRight: Radius.circular(cardRadius),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        cardPadH,
                        cardPadTop,
                        cardPadH,
                        cardPadBottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title,
                            style: GoogleFonts.montserrat(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 14 * scale),
                          Text(
                            slide.desc,
                            style: GoogleFonts.montserrat(
                              fontSize: descSize,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Dot indicators (above white card, centered) ──
          Positioned(
            top: imageHeight - (52 * scale),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                  width: _current == index ? dotActiveW : dotInactiveW,
                  height: dotH,
                  decoration: BoxDecoration(
                    color: _current == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(dotH / 2),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar: welcome text + logo ──
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scale,
                vertical: 16 * scale,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang\ndi Agrivana!',
                    style: GoogleFonts.montserrat(
                      fontSize: welcomeSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  Image.asset(
                    'assets/images/agrivana-white-logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom buttons: "Lewati" + image button ──
          Positioned(
            bottom: bottomOffset,
            left: sideInset,
            right: sideInset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Lewati" pill button with gray background
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.login),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: lewatiPadH,
                      vertical: lewatiPadV,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.montserrat(
                        fontSize: lewatiFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Next button using image asset
                GestureDetector(
                  onTap: () {
                    if (_current < 2) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login);
                    }
                  },
                  child: Image.asset(
                    'assets/images/splash_onboarding/onboarding-btn.png',
                    width: btnImgSize,
                    height: btnImgSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String desc;
  final String image;
  const _SlideData({
    required this.title,
    required this.desc,
    required this.image,
  });
}
