import 'package:flutter/material.dart';
import '../models/isaac_entry.dart';
import '../services/data_repository.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _typeFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DataRepository.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _typeChip({required String label, required String? value}) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _typeFilter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = DataRepository.instance;
    final results = _loading
        ? <IsaacEntry>[]
        : repo.search(_query, typeFilter: _typeFilter);

    return Scaffold(
      appBar: AppBar(title: const Text('Isaac Codex')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Type an item name (e.g. Brimstone, Sacred Heart)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (!_loading)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _typeChip(label: 'All', value: null),
                  for (final tf in kTypeFilters)
                    _typeChip(
                      label: '${tf.icon} ${tf.label}',
                      value: tf.id,
                    ),
                ],
              ),
            ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${results.length} results',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_query.isEmpty)
                    Text(
                      'A-Z',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No matching items.\nTry a different spelling.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, i) =>
                            _EntryTile(entry: results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final IsaacEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          categoryIcon(entry.category),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      title: Text(
        entry.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entry.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PowerBadge(power: entry.power),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetailScreen(entry: entry),
        ),
      ),
    );
  }
}

/// 0-10 power badge with colour coded tiers.
class PowerBadge extends StatelessWidget {
  final int? power;
  final double size;
  const PowerBadge({super.key, required this.power, this.size = 36});

  static Color colorFor(int? p) {
    if (p == null) return Colors.blueGrey;
    if (p <= 2) return Colors.redAccent;
    if (p <= 4) return Colors.orangeAccent;
    if (p <= 6) return Colors.amber;
    if (p <= 8) return Colors.lightGreen;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(power);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        power == null ? '-' : '$power',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}
