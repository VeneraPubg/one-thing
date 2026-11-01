import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/someday/presentation/someday_screen.dart';
import '../../features/summary/presentation/summary_screen.dart';
import '../../features/today/presentation/today_screen.dart';

class AppRouter {
  static const todayPath = '/today';
  static const somedayPath = '/someday';
  static const settingsPath = '/settings';
  static const summaryPath = '/summary';

  static GoRouter build() {
    return GoRouter(
      initialLocation: todayPath,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: todayPath,
                builder: (context, state) => const TodayScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: somedayPath,
                builder: (context, state) => const SomedayScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: settingsPath,
                builder: (context, state) => const SettingsScreen(),
              ),
            ]),
          ],
        ),
        GoRoute(
          path: summaryPath,
          builder: (context, state) => const SummaryScreen(),
        ),
      ],
    );
  }
}

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E4DE),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          selectedItemColor: accent,
          unselectedItemColor: isDark
              ? const Color(0xFFA1A1A6)
              : const Color(0xFF6E6E73),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _NavItemIcon(
                icon: Icons.sunny,
                index: 0,
                currentIndex: navigationShell.currentIndex,
                accent: accent,
                label: 'Сегодня',
              ),
              label: 'Сегодня',
            ),
            BottomNavigationBarItem(
              icon: _NavItemIcon(
                icon: Icons.all_inclusive,
                index: 1,
                currentIndex: navigationShell.currentIndex,
                accent: accent,
                label: 'Когда-нибудь',
              ),
              label: 'Когда-нибудь',
            ),
            BottomNavigationBarItem(
              icon: _NavItemIcon(
                icon: Icons.tune,
                index: 2,
                currentIndex: navigationShell.currentIndex,
                accent: accent,
                label: 'Настройки',
              ),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final Color accent;
  final String label;

  const _NavItemIcon({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Icon(icon, size: 24, color: isSelected ? accent : null),
    );
  }
}
