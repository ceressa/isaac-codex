import 'package:flutter/material.dart';
import '../item_sprite.dart';
import '../models/isaac_entry.dart';
import '../responsive.dart';
import 'search_screen.dart' show PowerBadge;

class DetailScreen extends StatelessWidget {
  final IsaacEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTr = entry.descriptionTr.isNotEmpty;
    final desc = hasTr ? entry.descriptionTr : entry.description;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ContentWrap(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemSprite(entry: entry, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      if (entry.nameTr.isNotEmpty)
                        Text(entry.nameTr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            )),
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel(entry.category),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    PowerBadge(power: entry.power, size: 56),
                    const SizedBox(height: 4),
                    Text(
                      entry.powerLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: PowerBadge.colorFor(entry.power),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.pickup.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${entry.pickup}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry.idNumber != null)
                  _Chip('${entry.idKind}: ${entry.idNumber}'),
                ...entry.metadata.entries.map(
                  (e) => _Chip('${e.key}: ${e.value}'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: 8),
            ...desc.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(d, style: theme.textTheme.bodyLarge),
                )),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Tags',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags.map((t) => _Chip(t)).toList(),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
