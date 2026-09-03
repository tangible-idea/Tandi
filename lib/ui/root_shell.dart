import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/download_service.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// 화면 폭에 따라 하단 탭 / 사이드 레일로 바뀌는 최상위 뼈대.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const int _homeIndex = 0;
  static const int _profileIndex = 1;
  static const int _settingsIndex = 3;

  int _index = _homeIndex;

  /// 홈에서 프로필 링크를 만났을 때 프로필 화면을 직접 열기 위해 필요하다.
  final _profileKey = GlobalKey<ProfileScreenState>();

  @override
  Widget build(BuildContext context) {
    final activeDownloads = context.select<DownloadService, int>(
      (service) => service.activeCount,
    );

    final destinations = <_Destination>[
      const _Destination(
        icon: Icons.download_outlined,
        selectedIcon: Icons.download,
        label: '다운로드',
      ),
      const _Destination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: '프로필',
      ),
      _Destination(
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        label: '목록',
        badgeCount: activeDownloads,
      ),
      const _Destination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: '설정',
      ),
    ];

    final pages = IndexedStack(
      index: _index,
      children: [
        HomeScreen(
          onOpenSettings: () => setState(() => _index = _settingsIndex),
          onOpenProfile: _openProfile,
        ),
        ProfileScreen(
          key: _profileKey,
          onOpenSettings: () => setState(() => _index = _settingsIndex),
        ),
        const DownloadsScreen(),
        const SettingsScreen(),
      ],
    );

    // 넓은 화면(데스크톱·태블릿)에서는 세로 레일이 더 편하다.
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.buildIcon(context, selected: false),
                    selectedIcon: destination.buildIcon(
                      context,
                      selected: true,
                    ),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: destination.buildIcon(context, selected: false),
              selectedIcon: destination.buildIcon(context, selected: true),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  void _openProfile(String username) {
    setState(() => _index = _profileIndex);
    // 프로필 화면이 IndexedStack 안에 이미 만들어져 있으므로 바로 호출해도 되지만,
    // 첫 진입이라면 프레임이 지난 뒤에 state 가 준비된다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileKey.currentState?.openUsername(username);
    });
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// 0보다 크면 아이콘에 진행 중 개수를 배지로 붙인다.
  final int badgeCount;

  Widget buildIcon(BuildContext context, {required bool selected}) {
    final child = Icon(selected ? selectedIcon : icon);
    if (badgeCount <= 0) return child;
    return Badge.count(count: badgeCount, child: child);
  }
}
