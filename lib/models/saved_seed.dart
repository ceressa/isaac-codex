import 'dart:convert';

class SavedSeed {
  final String id;
  final String code;
  final String character;
  final String note;
  final DateTime savedAt;
  final List<String> tags;

  const SavedSeed({
    required this.id,
    required this.code,
    required this.character,
    required this.note,
    required this.savedAt,
    required this.tags,
  });

  SavedSeed copyWith({
    String? code,
    String? character,
    String? note,
    List<String>? tags,
  }) =>
      SavedSeed(
        id: id,
        code: code ?? this.code,
        character: character ?? this.character,
        note: note ?? this.note,
        savedAt: savedAt,
        tags: tags ?? this.tags,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'character': character,
        'note': note,
        'savedAt': savedAt.toIso8601String(),
        'tags': tags,
      };

  factory SavedSeed.fromJson(Map<String, dynamic> json) => SavedSeed(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        character: json['character'] as String? ?? '',
        note: json['note'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  /// Isaac seed codes are 8 alphanumeric chars, conventionally formatted as
  /// "XXXX YYYY". Normalises whatever the user typed.
  static String normaliseCode(String input) {
    final cleaned =
        input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length < 8) return cleaned;
    return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)}';
  }
}

const List<String> kCharacters = [
  'Isaac',
  'Magdalene',
  'Cain',
  'Judas',
  '???',
  'Eve',
  'Samson',
  'Azazel',
  'Lazarus',
  'Eden',
  'The Lost',
  'Lilith',
  'Keeper',
  'Apollyon',
  'The Forgotten',
  'Bethany',
  'Jacob & Esau',
  'T. Isaac',
  'T. Magdalene',
  'T. Cain',
  'T. Judas',
  'T. ???',
  'T. Eve',
  'T. Samson',
  'T. Azazel',
  'T. Lazarus',
  'T. Eden',
  'T. The Lost',
  'T. Lilith',
  'T. Keeper',
  'T. Apollyon',
  'T. The Forgotten',
  'T. Bethany',
  'T. Jacob',
];

String encodeSeeds(List<SavedSeed> seeds) =>
    jsonEncode(seeds.map((s) => s.toJson()).toList());

List<SavedSeed> decodeSeeds(String raw) {
  if (raw.isEmpty) return [];
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => SavedSeed.fromJson(e as Map<String, dynamic>))
      .toList();
}
