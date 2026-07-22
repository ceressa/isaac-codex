import 'package:flutter/material.dart';
import 'models/isaac_entry.dart';

/// Renders an item's pixel-art sprite crisply (no smoothing). Falls back to the
/// emoji category icon when the item has no sprite or the asset is missing.
class ItemSprite extends StatelessWidget {
  final IsaacEntry entry;
  final double size;
  const ItemSprite({super.key, required this.entry, this.size = 40});

  Widget _fallback() => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            categoryIcon(entry.category),
            style: TextStyle(fontSize: size * 0.62),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (entry.sprite.isEmpty) return _fallback();
    return Image.asset(
      entry.sprite,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }
}
