import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'clipboard_snapshot.dart';

const _htmlMime = 'text/html';
const _textMime = 'text/plain';

/// Reads `text/html`, `text/plain` and the first `image/*` item with a single
/// async Clipboard API call.
///
/// The first read shows the browser's permission prompt, which takes focus
/// from the page; Chrome then rejects clipboard calls with "Document is not
/// focused". In that case this waits for focus to return and retries once.
Future<ClipboardSnapshot> readClipboard() async {
  try {
    return await _read();
  } catch (_) {
    if (web.document.hasFocus()) return ClipboardSnapshot.unavailable;
  }
  if (!await waitForDocumentFocus()) return ClipboardSnapshot.unavailable;
  try {
    return await _read();
  } catch (_) {
    return ClipboardSnapshot.unavailable;
  }
}

Future<ClipboardSnapshot> _read() async {
  final items = (await web.window.navigator.clipboard.read().toDart).toDart;
  String? html;
  String? text;
  ClipboardImage? image;
  for (final item in items) {
    final types = item.types.toDart.map((t) => t.toDart).toList();
    if (html == null && types.contains(_htmlMime)) {
      final blob = await item.getType(_htmlMime).toDart;
      html = (await blob.text().toDart).toDart;
    }
    if (text == null && types.contains(_textMime)) {
      final blob = await item.getType(_textMime).toDart;
      text = (await blob.text().toDart).toDart;
    }
    if (image == null) {
      final imageType = types.where((t) => t.startsWith('image/')).firstOrNull;
      if (imageType != null) {
        final blob = await item.getType(imageType).toDart;
        final buffer = (await blob.arrayBuffer().toDart).toDart;
        image = ClipboardImage(buffer.asUint8List(), imageType);
      }
    }
  }
  return ClipboardSnapshot(html: html, text: text, image: image);
}

/// Waits until the page has focus again (e.g. after a permission prompt).
/// Returns false on timeout.
Future<bool> waitForDocumentFocus({
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!web.document.hasFocus()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return true;
}

/// Writes [html] as `text/html` and [plainText] as `text/plain`.
/// Returns false if the Clipboard API rejected the write.
Future<bool> writeClipboardHtml(String html, {required String plainText}) async {
  try {
    web.Blob blob(String data, String type) =>
        web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: type));
    final item = web.ClipboardItem(
      {
        _htmlMime: blob(html, _htmlMime),
        _textMime: blob(plainText, _textMime),
      }.jsify() as JSObject,
    );
    await web.window.navigator.clipboard.write([item].toJS).toDart;
    return true;
  } catch (_) {
    return false;
  }
}
