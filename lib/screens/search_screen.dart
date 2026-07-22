import 'package:flutter/material.dart';
import '../item_sprite.dart';
import '../models/isaac_entry.dart';
import '../responsive.dart';
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

  Widget _typeChip({String? icon, required String label, required String? value}) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: (icon == null || icon.isEmpty)
            ? null
            : Text(icon, style: const TextStyle(fontSize: 15)),
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
    final wide = isWide(context);

    final header = ContentWrap(
      maxWidth: 1080,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TextField(
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
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          if (!_loading)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _typeChip(label: 'All', value: null),
                  for (final tf in kTypeFilters)
                    _typeChip(icon: tf.icon, label: tf.label, value: tf.id),
                ],
              ),
            ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${results.length} results',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (_query.isEmpty)
                    Text('A-Z',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );

    Widget resultsView;
    if (_loading) {
      resultsView = const Center(child: CircularProgressIndicator());
    } else if (results.isEmpty) {
      resultsView = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No matching items.\nTry a different spelling.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else if (wide) {
      resultsView = ContentWrap(
        maxWidth: 1080,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisExtent: 78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) => _EntryCard(entry: results[i]),
        ),
      );
    } else {
      resultsView = ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, i) => _EntryTile(entry: results[i]),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Isaac Codex'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          header,
          Expanded(child: resultsView),
        ],
      ),
    );
  }
}

/// Compact card used in the wide/grid layout.
class _EntryCard extends StatelessWidget {
  final IsaacEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(entry: entry)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ItemSprite(entry: entry, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PowerBadge(power: entry.power, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width tile used in the narrow/list layout.
class _EntryTile extends StatelessWidget {
  final IsaacEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ItemSprite(entry: entry, size: 40),
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
    switch (p) {
      case 0:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
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
