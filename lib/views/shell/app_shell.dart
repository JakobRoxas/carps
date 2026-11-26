import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';

class _Tab {
  const _Tab(this.path, this.label, this.icon, this.activeIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _Tab('/home', 'Home', CarpsIcons.house, CarpsIcons.houseFill),
  _Tab('/feed', 'Feed', CarpsIcons.squaresFour,
      CarpsIcons.squaresFourFill),
  _Tab('/profile', 'Profile', CarpsIcons.userCircle,
      CarpsIcons.userCircleFill),
  _Tab('/settings', 'Settings', CarpsIcons.gearSix,
      CarpsIcons.gearSixFill),
];

/// Phones show bottom nav on the main sections; desktop keeps a rail across
/// app pages, with Explore and a persistent Create event action.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final body = SafeArea(bottom: false, child: child);
    if (width < 600) {
      if (!_tabs.any((tab) => location.startsWith(tab.path))) return child;
      return Scaffold(
        body: body,
        bottomNavigationBar: _BottomNav(location: location),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          _Rail(location: location, expanded: width >= 840),
          VerticalDivider(width: 1, color: context.carps.borderSubtle),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    Widget item(_Tab t) {
      final active = location.startsWith(t.path);
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          label: t.label,
          child: InkWell(
            onTap: () => context.go(t.path),
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active ? t.activeIcon : t.icon,
                      size: 24,
                      color: active ? c.textPrimary : c.textSecondary),
                  const SizedBox(height: 4),
                  ExcludeSemantics(
                    child: Text(t.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active ? c.textPrimary : c.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0A0A0A), blurRadius: 32, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            item(_tabs[0]),
            item(_tabs[1]),
            Expanded(
              // The ＋ is raised above the bar without growing its height.
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    top: -22,
                    child: Semantics(
                      button: true,
                      label: 'Create event',
                      child: Tooltip(
                        message: 'Create event',
                        child: Material(
                          color: c.accentFill,
                          shape: CircleBorder(
                              side: BorderSide(color: c.canvas, width: 4)),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => context.push('/create'),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(CarpsIcons.plusBold,
                                  size: 28, color: c.onAccent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: ExcludeSemantics(
                      child: Text('Create',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: c.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
            item(_tabs[2]),
            item(_tabs[3]),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.location, required this.expanded});
  final String location;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final tabs = [
      _tabs[0],
      const _Tab(
        '/search',
        'Explore',
        CarpsIcons.magnifyingGlass,
        CarpsIcons.magnifyingGlass,
      ),
      ..._tabs.skip(1),
    ];
    final selected = tabs.indexWhere((t) => location.startsWith(t.path));
    return Container(
      color: c.canvas,
      width: expanded ? 220 : 88,
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              expanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0),
              child: expanded
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: CarpsWordmark(size: 26))
                  : const CarpsWordmark(size: 16),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 12),
              child: expanded
                  ? CarpsButton(
                      label: 'Create event',
                      icon: CarpsIcons.plusBold,
                      height: 48,
                      onPressed: () => context.push('/create'))
                  : Tooltip(
                      message: 'Create event',
                      child: Material(
                        color: c.accentFill,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.push('/create'),
                          child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(CarpsIcons.plusBold,
                                  color: c.onAccent)),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 12 : 8, vertical: 2),
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  child: Material(
                    color: i == selected ? c.muted : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go(tabs[i].path),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: expanded
                            ? Row(children: [
                                Icon(
                                    i == selected
                                        ? tabs[i].activeIcon
                                        : tabs[i].icon,
                                    color: i == selected
                                        ? c.textPrimary
                                        : c.textSecondary),
                                const SizedBox(width: 12),
                                Text(tabs[i].label,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: i == selected
                                            ? c.textPrimary
                                            : c.textSecondary)),
                              ])
                            : Column(children: [
                                Icon(
                                    i == selected
                                        ? tabs[i].activeIcon
                                        : tabs[i].icon,
                                    color: i == selected
                                        ? c.textPrimary
                                        : c.textSecondary),
                                const SizedBox(height: 4),
                                Text(tabs[i].label,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: i == selected
                                            ? c.textPrimary
                                            : c.textSecondary)),
                              ]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
