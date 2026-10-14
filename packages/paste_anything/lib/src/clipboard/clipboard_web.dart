import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'pae_clip.dart';

const _htmlMime = 'text/html';
const _textMime = 'text/plain';

web.Clipboard get _clipboard => web.window.navigator.clipboard;

Future<PaeClip> readClip() async {
  try {
    return await _read();
  } catch (_) {
    // Chrome rejects with "Document is not focused" right after the
    // permission prompt; anything else is a real failure.
    if (web.document.hasFocus()) return PaeClip.unavailable;
  }
  if (!await waitForFocus(const Duration(seconds: 3))) {
    return PaeClip.unavailable;
  }
  try {
    return await _read();
  } catch (_) {
    return PaeClip.unavailable;
  }
}

Future<PaeClip> _read() async {
  final items = (await _clipboard.read().toDart).toDart;
  String? html;
  String? text;
  PaeImage? image;
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
        image = PaeImage(buffer.asUint8List(), imageType);
      }
    }
  }
  return PaeClip(html: html, text: text, image: image);
}

Future<String?> readPlainText() async {
  try {
    return (await _clipboard.readText().toDart).toDart;
  } catch (_) {
    return null;
  }
}

Future<bool> writeHtml(String html, String plainText) async {
  try {
    web.Blob blob(String data, String type) =>
        web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: type));
    final item = web.ClipboardItem(
      {
        _htmlMime: blob(html, _htmlMime),
        _textMime: blob(plainText, _textMime),
      }.jsify() as JSObject,
    );
    await _clipboard.write([item].toJS).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> writeText(String text) async {
  try {
    await _clipboard.writeText(text).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> waitForFocus(Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (!web.document.hasFocus()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return true;
}
