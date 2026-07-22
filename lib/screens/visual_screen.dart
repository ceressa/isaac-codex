import 'package:flutter/material.dart';
import '../item_sprite.dart';
import '../models/isaac_entry.dart';
import '../responsive.dart';
import '../services/data_repository.dart';
import 'detail_screen.dart';

/// Dense grid of every item sprite for visual identification: "I picked this up,
/// what is it?" Hover (web) or tap shows the name; tap opens the detail.
class VisualScreen extends StatefulWidget {
  const VisualScreen({super.key});

  @override
  State<VisualScreen> createState() => _VisualScreenState();
}

class _VisualScreenState extends State<VisualScreen> {
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    DataRepository.instance.load();
    DataRepository.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    DataRepository.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Widget _chip(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: _typeFilter == value,
        onSelected: (_) => setState(() => _typeFilter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = DataRepository.instance;
    final entries = repo.isLoaded
        ? repo.search('', typeFilter: _typeFilter)
        : <IsaacEntry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Visual'), centerTitle: false),
      body: !repo.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ContentWrap(
                    maxWidth: 1080,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chip('All', null),
                        for (final tf in kTypeFilters)
                          _chip('${tf.icon} ${tf.label}', tf.id),
                      ],
                    ),
                  ),
                ),
                ContentWrap(
                  maxWidth: 1080,
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${entries.length} items - tap a sprite to identify it',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: ContentWrap(
                    maxWidth: 1080,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 72,
                        mainAxisExtent: 72,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return Tooltip(
                          message: e.name,
                          waitDuration: const Duration(milliseconds: 250),
                          child: Material(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(entry: e),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: ItemSprite(entry: e, size: 54),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
