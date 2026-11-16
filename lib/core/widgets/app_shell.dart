// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';

import 'common.dart';

class ShellTab {
  const ShellTab(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// Role-aware shell: bottom navigation on phones, navigation rail on
/// tablets (≥ 840 px). Tabs keep their state.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.tabs, this.initial = 0});
  final List<ShellTab> tabs;
  final int initial;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initial;
  late final _built = <int, Widget>{};
  // Moves the tab bodies (and their scroll/form state) between the rail and
  // bottom-bar layouts instead of rebuilding them when a foldable opens or closes.
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    _built.putIfAbsent(
      _index,
      () => Builder(builder: widget.tabs[_index].builder),
    );
    final body = KeyedSubtree(
      key: _bodyKey,
      child: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            _built[i] ?? const SizedBox.shrink(),
        ],
      ),
    );
    void select(int i) => setState(() => _index = i);
    if (Breakpoints.wide(context)) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final t in widget.tabs)
                    NavigationRailDestination(
                      icon: Icon(t.icon),
                      label: Text(t.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          for (final t in widget.tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
