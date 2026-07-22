// Non-web fallback: use the clipboard (no native file dialog wired up here).
import 'package:flutter/services.dart';

/// Copies [json] to the clipboard. Returns false (nothing was saved to disk;
/// the caller should tell the user it was copied instead).
Future<bool> exportSeedsFile(String json, String filename) async {
  await Clipboard.setData(ClipboardData(text: json));
  return false;
}

/// Reads JSON text from the clipboard.
Future<String?> importSeedsFile() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  return data?.text;
}
