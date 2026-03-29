// Location: agrivana\lib\features\home\view\main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/bottom_nav_tutorial.dart';
import 'home_screen.dart';
import '../../shop/view/marketplace_screen.dart';
import '../../plant/view/plant_tracking_screen.dart';
import '../../education/view/article_list_screen.dart';
import '../../profile/view/profile_screen.dart';

/// InheritedWidget that allows children to switch the bottom nav tab.
class MainWrapperScope extends InheritedWidget {
  final void Function(int index) switchTab;

  const MainWrapperScope({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static MainWrapperScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainWrapperScope>();
  }

  @override
  bool updateShouldNotify(MainWrapperScope oldWidget) => false;
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _showTutorial = false;

  /// GlobalKeys for each bottom nav item (indices 0-4).
  final List<GlobalKey> _navKeys = List.generate(5, (_) => GlobalKey());

  final _screens = const [
    HomeScreen(),
    MarketplaceScreen(),
    PlantTrackingScreen(),
    ArticleListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenBottomNavTutorial') ?? false;
    if (!hasSeen && mounted) {
      // Delay to let the bottom nav fully render so GlobalKeys are available
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _showTutorial = true);
      }
    }
  }

  Future<void> _onTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenBottomNavTutorial', true);
    if (mounted) {
      setState(() => _showTutorial = false);
    }
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainWrapperScope(
      switchTab: _switchTab,
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            body: FadeIndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              navKeys: _navKeys,
            ),
          ),
          // Tutorial overlay
          if (_showTutorial)
            BottomNavTutorial(
              navKeys: _navKeys,
              onComplete: _onTutorialComplete,
            ),
        ],
      ),
    );
  }
}


class FadeIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(children.length, (i) {
        final active = index == i;
        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            opacity: active ? 1.0 : 0.0,
            duration: duration,
            curve: Curves.easeInOut,
            child: children[i],
          ),
        );
      }),
    );
  }
}
