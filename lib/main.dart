import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'shared/theme/app_theme.dart';
import 'features/device/device_screen.dart';
import 'features/activities/activities_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: SpeedCoachApp()));
}

class SpeedCoachApp extends StatelessWidget {
  const SpeedCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedCoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _navAnimationController;
  late final Animation<double> _navAnimation;

  final List<Widget> _screens = const [
    DeviceScreen(),
    ActivitiesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    _navAnimationController.reverse().then((_) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      _navAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF121212), const Color(0xFF0F0F1A)]
                      : [const Color(0xFFF8F9FD), const Color(0xFFFFFFFF), const Color(0xFFF0F4FF)],
                ),
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            physics: const NeverScrollableScrollPhysics(),
            children: _screens.asMap().entries.map((entry) {
              final index = entry.key;
              final screen = entry.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                child: _currentIndex == index
                    ? KeyedSubtree(key: ValueKey(index), child: screen)
                    : const SizedBox.shrink(),
              );
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1E1E).withValues(alpha: 0.95), const Color(0xFF121212)]
                : [Colors.white.withValues(alpha: 0.95), const Color(0xFFF8F9FD)],
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.bluetooth_outlined, Icons.bluetooth_connected, 'Appareil'),
                _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt, 'Activités'),
                _buildNavItem(2, Icons.settings_outlined, Icons.settings, 'Réglages'),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Expanded(
      child: AnimatedBuilder(
        animation: _navAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: () => _onTabChanged(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.15),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isSelected
                    ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: RotationTransition(turns: animation, child: child));
                    },
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      key: ValueKey(isSelected),
                      size: 26,
                      color: isSelected ? primaryColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 0.3,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}