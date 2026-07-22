import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/isaac_entry.dart';

class DataRepository extends ChangeNotifier {
  DataRepository._();
  static final DataRepository instance = DataRepository._();

  List<IsaacEntry> _entries = const [];
  bool _loaded = false;
  Future<void>? _loading;

  List<IsaacEntry> get entries => _entries;
  bool get isLoaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _doLoad();
  }

  Future<void> _doLoad() async {
    final raw = await rootBundle.loadString('assets/data/items.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = decoded['items'] as List;
    _entries = items
        .map((e) => IsaacEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _loaded = true;
    notifyListeners();
  }

  /// Lightweight ranked search.
  List<IsaacEntry> search(String query,
      {String? category, String? typeFilter, String? itemPool}) {
    final q = query.trim().toLowerCase();
    Iterable<IsaacEntry> pool = _entries;
    if (category != null) {
      pool = pool.where((e) => e.category == category);
    }
    if (typeFilter != null) {
      pool = pool.where((e) => matchesType(e, typeFilter));
    }
    if (itemPool != null) {
      pool = pool.where((e) => poolsOf(e).contains(itemPool));
    }
    final list = pool.toList();
    if (q.isEmpty) {
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }
    final scored = <(int, IsaacEntry)>[];
    for (final e in list) {
      final name = e.name.toLowerCase();
      final pickup = e.pickup.toLowerCase();
      int score = 0;
      if (name == q) {
        score = 100;
      } else if (name.startsWith(q)) {
        score = 80;
      } else if (name.contains(q)) {
        score = 60;
      } else if (pickup.contains(q)) {
        score = 40;
      } else if (e.description.any((d) => d.toLowerCase().contains(q))) {
        score = 20;
      } else if (e.descriptionTr.any((d) => d.toLowerCase().contains(q))) {
        score = 25;
      } else if (e.nameTr.toLowerCase().contains(q)) {
        score = 70;
      }
      if (score > 0) scored.add((score, e));
    }
    scored.sort((a, b) {
      final byScore = b.$1.compareTo(a.$1);
      if (byScore != 0) return byScore;
      return a.$2.name.compareTo(b.$2.name);
    });
    return scored.map((p) => p.$2).toList();
  }

  IsaacEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Map<String, int> categoryCounts() {
    final counts = <String, int>{};
    for (final e in _entries) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return counts;
  }

  int countByType(String typeFilter) {
    return _entries.where((e) => matchesType(e, typeFilter)).length;
  }

  /// Item counts per item pool (Treasure Room, Devil Room, Angel Room, ...).
  Map<String, int> poolCounts() {
    final counts = <String, int>{};
    for (final e in _entries) {
      for (final p in poolsOf(e)) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    return counts;
  }
}

/// The item pools an entry belongs to, from its "Item Pool" metadata.
List<String> poolsOf(IsaacEntry e) {
  final raw = e.metadata['Item Pool'] ?? '';
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Type filters operate on the metadata['Type'] field, which can be a
/// comma-separated list like "Passive, Familiar".
bool matchesType(IsaacEntry e, String typeFilter) {
  final t = (e.metadata['Type'] ?? '').toLowerCase();
  switch (typeFilter) {
    case 'active':
      return t.contains('active');
    case 'passive':
      return t.contains('passive');
    case 'familiar':
      return t.contains('familiar');
    case 'tear':
      return t.contains('tear');
    case 'orbital':
      return t.contains('orbital');
    case 'bomb':
      return t.contains('bomb modifier');
    default:
      return true;
  }
}

class TypeFilter {
  final String id;
  final String label;
  final String icon;
  const TypeFilter(this.id, this.label, this.icon);
}

const List<TypeFilter> kTypeFilters = [
  TypeFilter('active', 'Active', '⚡'),
  TypeFilter('passive', 'Passive', '🔒'),
  TypeFilter('familiar', 'Familiar', '👻'),
  TypeFilter('tear', 'Tear Modifier', '💧'),
  TypeFilter('orbital', 'Orbital', '🪐'),
  TypeFilter('bomb', 'Bomb Modifier', '💣'),
];
