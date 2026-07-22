import 'package:flutter/material.dart';

/// Width at or above which we treat the app as "desktop / web wide" and switch
/// from the mobile layout (bottom nav, full-width lists) to a rail + grid.
const double kWideBreakpoint = 760;

bool isWide(BuildContext context) =>
    MediaQuery.of(context).size.width >= kWideBreakpoint;

/// Centres content and caps its width so it does not sprawl edge-to-edge on a
/// wide browser window. On narrow screens it is a no-op (full width).
class ContentWrap extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ContentWrap({
    super.key,
    required this.child,
    this.maxWidth = 1080,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
