import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_seed.dart';

class SeedStore extends ChangeNotifier {
  SeedStore._();
  static final SeedStore instance = SeedStore._();

  static const _key = 'saved_seeds_v1';

  List<SavedSeed> _seeds = [];
  bool _loaded = false;

  List<SavedSeed> get seeds {
    final list = [..._seeds];
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '';
    _seeds = decodeSeeds(raw);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, encodeSeeds(_seeds));
    notifyListeners();
  }

  Future<void> add(SavedSeed seed) async {
    _seeds.add(seed);
    await _persist();
  }

  Future<void> update(SavedSeed seed) async {
    final i = _seeds.indexWhere((s) => s.id == seed.id);
    if (i < 0) return;
    _seeds[i] = seed;
    await _persist();
  }

  Future<void> remove(String id) async {
    _seeds.removeWhere((s) => s.id == id);
    await _persist();
  }
}
