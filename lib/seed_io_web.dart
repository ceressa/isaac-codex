// Web implementation: download / upload a JSON file via the browser.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Triggers a browser download of [json] as [filename]. Returns true (a real
/// file was saved).
Future<bool> exportSeedsFile(String json, String filename) async {
  final bytes = utf8.encode(json);
  final blob = html.Blob(<Object>[bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}

/// Opens a file picker and returns the chosen JSON file's text, or null.
Future<String?> importSeedsFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'application/json,.json';
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final reader = html.FileReader();
  reader.readAsText(files.first);
  await reader.onLoadEnd.first;
  return reader.result as String?;
}
