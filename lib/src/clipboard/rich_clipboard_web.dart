import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'clipboard_snapshot.dart';

const _htmlMime = 'text/html';
const _textMime = 'text/plain';

/// Reads `text/html` and the first `image/*` item via the async Clipboard API.
/// Returns [ClipboardSnapshot.empty] when unavailable or denied.
Future<ClipboardSnapshot> readClipboard() async {
  try {
    final items = (await web.window.navigator.clipboard.read().toDart).toDart;
    String? html;
    ClipboardImage? image;
    for (final item in items) {
      final types = item.types.toDart.map((t) => t.toDart).toList();
      if (html == null && types.contains(_htmlMime)) {
        final blob = await item.getType(_htmlMime).toDart;
        html = (await blob.text().toDart).toDart;
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
    return ClipboardSnapshot(html: html, image: image);
  } catch (_) {
    return ClipboardSnapshot.empty;
  }
}

/// Reads `text/html` from the clipboard, or null.
Future<String?> readClipboardHtml() async => (await readClipboard()).html;

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
