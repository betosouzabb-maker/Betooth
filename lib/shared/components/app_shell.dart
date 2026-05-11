import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../widgets/mini_player_widget.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  static const tabs = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Biblioteca', icon: Icons.library_music_rounded),
    _NavItem(label: 'Busca', icon: Icons.search_rounded),
    _NavItem(label: 'Playlists', icon: Icons.queue_music_rounded),
    _NavItem(label: 'Perfil', icon: Icons.person_rounded),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.card,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerWidget(),
              BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTap,
                items: tabs
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}