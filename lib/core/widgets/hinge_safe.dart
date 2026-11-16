// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';

/// Keeps the app off a hinge or half-open fold by using the larger sub-screen,
/// and reports that sub-screen's size so breakpoints see the room really left.
///
/// The tree shape never changes with the hinge: the Navigator below must not
/// be re-created when the device folds, or the whole app state would reset.
/// shortcut: one pane only, no list/detail split across the hinge; add a
/// two-pane layout if foldable users need it.
class HingeSafe extends StatelessWidget {
  const HingeSafe({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final full = Offset.zero & mq.size;
    final subScreens = DisplayFeatureSubScreen.subScreensInBounds(
      full,
      DisplayFeatureSubScreen.avoidBounds(mq),
    );
    final main = subScreens.fold<Rect>(
      subScreens.isEmpty ? full : subScreens.first,
      (a, b) => a.width * a.height >= b.width * b.height ? a : b,
    );
    return DisplayFeatureSubScreen(
      anchorPoint: main.center,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: main.size),
          child: child,
        ),
      ),
    );
  }
}
