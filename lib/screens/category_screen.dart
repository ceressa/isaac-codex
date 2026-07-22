import 'package:flutter/material.dart';
import '../models/isaac_entry.dart';
import '../responsive.dart';
import '../services/data_repository.dart';
import 'detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final repo = DataRepository.instance;
    if (!repo.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final counts = repo.categoryCounts();
    final visibleSources = kCategories
        .where((c) => (counts[c.id] ?? 0) > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), centerTitle: false),
      body: ContentWrap(
        maxWidth: 760,
        child: ListView(
          children: [
            _SectionHeader(title: 'By type'),
            ...kTypeFilters.map((tf) {
              final count = repo.countByType(tf.id);
              return ListTile(
                leading: Text(tf.icon, style: const TextStyle(fontSize: 24)),
                title: Text(tf.label),
                subtitle: Text('$count items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TypeListScreen(filter: tf),
                  ),
                ),
              );
            }),
            const Divider(height: 24),
            _SectionHeader(title: 'By source'),
            ...visibleSources.map((c) => ListTile(
                  leading: Text(c.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(c.label),
                  subtitle: Text('${counts[c.id]} items'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryListScreen(category: c),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class CategoryListScreen extends StatefulWidget {
  final CategoryInfo category;
  const CategoryListScreen({super.key, required this.category});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final entries = DataRepository.instance.search(
      '',
      category: widget.category.id,
      typeFilter: _typeFilter,
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.label)),
      body: ContentWrap(
        maxWidth: 760,
        child: Column(
          children: [
            _FilterChips(
              selected: _typeFilter,
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No items for this filter.'))
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _entryTile(context, entries[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeListScreen extends StatelessWidget {
  final TypeFilter filter;
  const TypeListScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final entries = DataRepository.instance.search('', typeFilter: filter.id);
    return Scaffold(
      appBar: AppBar(title: Text('${filter.icon} ${filter.label}')),
      body: ContentWrap(
        maxWidth: 760,
        child: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) => _entryTile(context, entries[i]),
        ),
      ),
    );
  }
}

Widget _entryTile(BuildContext context, IsaacEntry e) {
  return ListTile(
    leading: Text(categoryIcon(e.category),
        style: const TextStyle(fontSize: 20)),
    title: Text(e.name),
    subtitle: Text(
      e.metadata['Type'] ?? e.section,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(entry: e)),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _chip(context, label: 'All', value: null),
          ...kTypeFilters.map(
            (tf) => _chip(context, label: '${tf.icon} ${tf.label}', value: tf.id),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required String? value}) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onChanged(value),
      ),
    );
  }
}
