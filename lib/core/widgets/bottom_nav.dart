// Location: agrivana\lib\core\widgets\bottom_nav.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Optional keys so the tutorial overlay can locate each nav item.
  final List<GlobalKey>? navKeys;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.navKeys,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 90,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 64,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined),
                  _navItem(1, Icons.shopping_bag_rounded, Icons.shopping_bag_outlined),
                  const SizedBox(width: 60), // Room for floating center item
                  _navItem(3, Icons.menu_book_rounded, Icons.menu_book_outlined),
                  _navItem(4, Icons.person_rounded, Icons.person_outline_rounded),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              child: _centerItem(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isActive = currentIndex == index;
    // Map nav index → key list index: 0→0, 1→1, 3→3, 4→4
    final key = navKeys != null && index < navKeys!.length ? navKeys![index] : null;
    return GestureDetector(
      key: key,
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isActive ? activeIcon : inactiveIcon,
            size: 26,
            color: isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _centerItem() {
    final isActive = currentIndex == 2;
    final key = navKeys != null && navKeys!.length > 2 ? navKeys![2] : null;
    return GestureDetector(
      key: key,
      onTap: () => onTap(2),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: isActive ? AppTheme.primary.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.eco_outlined,
            size: 32,
            color: isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
