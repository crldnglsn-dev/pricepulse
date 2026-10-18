import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';

/// App shell — bottom navigation (Home | Favorites | Account) + tab states.
/// Spec: design/01 §2.2, design/02 §2.10 `BottomNav`.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _selectTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onAccountTap: () => _selectTab(2)),
          FavoritesScreen(onDiscover: () => _selectTab(0)),
          AccountScreen(onFavoritesTap: () => _selectTab(1)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: _BounceIcon(icon: Icons.home_outlined, selected: _index == 0),
            selectedIcon: _BounceIcon(
              icon: Icons.home_rounded,
              selected: _index == 0,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _BounceIcon(
              icon: Icons.favorite_border_rounded,
              selected: _index == 1,
            ),
            selectedIcon: _BounceIcon(
              icon: Icons.favorite_rounded,
              selected: _index == 1,
            ),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: _BounceIcon(
              icon: Icons.person_outline_rounded,
              selected: _index == 2,
            ),
            selectedIcon: _BounceIcon(
              icon: Icons.person_rounded,
              selected: _index == 2,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

/// A nav icon that pops when its tab is selected.
///
/// The scale is a transform, not a layout change, so the icon never shifts
/// its neighbours or resizes the bar.
class _BounceIcon extends StatefulWidget {
  const _BounceIcon({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selected) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_BounceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward(from: 0);
    } else if (!widget.selected && oldWidget.selected) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // A half sine: up and back down, never past the resting size.
        final pop = math.sin(math.pi * _controller.value);
        return Transform.scale(scale: 1 + 0.22 * pop, child: child);
      },
      child: Icon(widget.icon),
    );
  }
}
