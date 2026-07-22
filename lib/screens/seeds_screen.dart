import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_seed.dart';
import '../services/seed_store.dart';

class SeedsScreen extends StatefulWidget {
  const SeedsScreen({super.key});

  @override
  State<SeedsScreen> createState() => _SeedsScreenState();
}

class _SeedsScreenState extends State<SeedsScreen> {
  @override
  void initState() {
    super.initState();
    SeedStore.instance.load();
    SeedStore.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    SeedStore.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final seeds = SeedStore.instance.seeds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Seeds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Preset Seeds',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PresetSeedsScreen()),
            ),
          ),
        ],
      ),
      body: !SeedStore.instance.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : seeds.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No seeds yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save the code from Options -> Seeded Run in-game '
                          'using the + button below. Never lose a good run.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: seeds.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _SeedTile(seed: seeds[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Seed'),
      ),
    );
  }
}

class _SeedTile extends StatelessWidget {
  final SavedSeed seed;
  const _SeedTile({required this.seed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Row(
        children: [
          SelectableText(
            seed.code,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: seed.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${seed.code} copied'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seed.character.isNotEmpty)
            Text('${seed.character} · ${_dateLabel(seed.savedAt)}'),
          if (seed.character.isEmpty) Text(_dateLabel(seed.savedAt)),
          if (seed.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                seed.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (v) async {
          if (v == 'edit') {
            _openEditor(context, seed);
          } else if (v == 'delete') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Delete ${seed.code}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await SeedStore.instance.remove(seed.id);
            }
          }
        },
      ),
      onTap: () => _openEditor(context, seed),
    );
  }
}

String _dateLabel(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$day.$m.${d.year}';
}

Future<void> _openEditor(BuildContext context, SavedSeed? existing) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SeedEditor(existing: existing),
  );
}

class PresetSeedsScreen extends StatefulWidget {
  const PresetSeedsScreen({super.key});

  @override
  State<PresetSeedsScreen> createState() => _PresetSeedsScreenState();
}

class _PresetSeedsScreenState extends State<PresetSeedsScreen> {
  List<_PresetSeed> _presets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/preset_seeds.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['seeds'] as List)
        .map((e) => _PresetSeed.fromJson(e as Map<String, dynamic>))
        .toList();
    if (mounted) {
      setState(() {
        _presets = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preset Seeds')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Repentance "Special Seeds" codes that modify the game in '
                    'strange ways. Tap to save one to your list.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _presets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _presets[i];
                      return ListTile(
                        title: Row(
                          children: [
                            SelectableText(
                              p.code,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(p.effect),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_add_outlined),
                          tooltip: 'Add to my list',
                          onPressed: () async {
                            await SeedStore.instance.add(SavedSeed(
                              id: DateTime.now()
                                  .microsecondsSinceEpoch
                                  .toString(),
                              code: p.code,
                              character: '',
                              note: '${p.name}: ${p.effect}',
                              savedAt: DateTime.now(),
                              tags: const ['preset'],
                            ));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.code} added'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: p.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${p.code} copied'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PresetSeed {
  final String code;
  final String name;
  final String effect;
  const _PresetSeed(this.code, this.name, this.effect);
  factory _PresetSeed.fromJson(Map<String, dynamic> j) => _PresetSeed(
        j['code'] as String,
        j['name'] as String,
        j['effect'] as String,
      );
}

class SeedEditor extends StatefulWidget {
  final SavedSeed? existing;
  const SeedEditor({super.key, this.existing});

  @override
  State<SeedEditor> createState() => _SeedEditorState();
}

class _SeedEditorState extends State<SeedEditor> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _noteCtrl;
  String _character = '';

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.existing?.code ?? '');
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _character = widget.existing?.character ?? '';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = SavedSeed.normaliseCode(_codeCtrl.text);
    if (code.replaceAll(' ', '').length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid seed code')),
      );
      return;
    }
    final base = widget.existing ??
        SavedSeed(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          code: code,
          character: _character,
          note: _noteCtrl.text.trim(),
          savedAt: DateTime.now(),
          tags: const [],
        );
    final seed = base.copyWith(
      code: code,
      character: _character,
      note: _noteCtrl.text.trim(),
    );
    if (widget.existing == null) {
      await SeedStore.instance.add(seed);
    } else {
      await SeedStore.instance.update(seed);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'New Seed' : 'Edit Seed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Seed code (8 characters)',
              hintText: 'ABCD 1234',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9 ]'),
              ),
              LengthLimitingTextInputFormatter(9),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _character.isEmpty ? null : _character,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Character (optional)',
              border: OutlineInputBorder(),
            ),
            items: kCharacters
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _character = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. double Sacred Heart in Basement',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
