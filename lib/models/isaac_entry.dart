import 'package:flutter/foundation.dart';

@immutable
class IsaacEntry {
  final String id;
  final String slug;
  final String category;
  final String section;
  final String name;
  final String nameTr;
  final String idKind;
  final int? idNumber;
  final String pickup;
  final int? quality;
  final List<String> description;
  final List<String> descriptionTr;
  final Map<String, String> metadata;
  final List<String> tags;

  const IsaacEntry({
    required this.id,
    required this.slug,
    required this.category,
    required this.section,
    required this.name,
    required this.nameTr,
    required this.idKind,
    required this.idNumber,
    required this.pickup,
    required this.quality,
    required this.description,
    required this.descriptionTr,
    required this.metadata,
    required this.tags,
  });

  factory IsaacEntry.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    Map<String, String> strMap(dynamic v) {
      if (v is! Map) return const {};
      return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
    }

    return IsaacEntry(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? 'unknown',
      section: json['section'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameTr: json['name_tr'] as String? ?? '',
      idKind: json['id_kind'] as String? ?? '',
      idNumber: json['id_number'] as int?,
      pickup: json['pickup'] as String? ?? '',
      quality: json['quality'] as int?,
      description: strList(json['description']),
      descriptionTr: strList(json['description_tr']),
      metadata: strMap(json['metadata']),
      tags: strList(json['tags']),
    );
  }

  bool get hasTurkish => nameTr.isNotEmpty || descriptionTr.isNotEmpty;

  String get displayName => name;
  String get subtitle {
    final type = metadata['Type'];
    if (type != null && type.isNotEmpty) return '$section · $type';
    return section;
  }

  /// Derive a 0-10 power rating from the official platinumgod quality
  /// (which is 0-4). Returns null when quality is unknown.
  int? get power {
    final q = quality;
    if (q == null) return null;
    return (q.clamp(0, 4) * 2.5).round().clamp(0, 10);
  }

  String get powerLabel {
    final p = power;
    if (p == null) return '-';
    if (p <= 2) return 'Weak';
    if (p <= 4) return 'Average';
    if (p <= 6) return 'Good';
    if (p <= 8) return 'Strong';
    return 'S Tier';
  }
}

class CategoryInfo {
  final String id;
  final String label;
  final String icon;
  const CategoryInfo(this.id, this.label, this.icon);
}

const List<CategoryInfo> kCategories = [
  CategoryInfo('repentance_item', 'Repentance Item', '🆕'),
  CategoryInfo('rebirth_item', 'Rebirth Item', '🎮'),
  CategoryInfo('afterbirth_item', 'Afterbirth Item', '🌒'),
  CategoryInfo('afterbirth_plus_item', 'Afterbirth+ Item', '🌓'),
  CategoryInfo('repentance_trinket', 'Repentance Trinket', '🆕'),
  CategoryInfo('trinket', 'Trinket', '🪙'),
  CategoryInfo('card', 'Card / Rune', '🃏'),
  CategoryInfo('repentance_consumable', 'Repentance Consumable', '🧪'),
  CategoryInfo('consumable', 'Consumable', '🧪'),
];

String categoryLabel(String id) {
  for (final c in kCategories) {
    if (c.id == id) return c.label;
  }
  return id;
}

String categoryIcon(String id) {
  for (final c in kCategories) {
    if (c.id == id) return c.icon;
  }
  return '❓';
}
