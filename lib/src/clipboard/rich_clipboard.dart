import 'package:flutter/services.dart';

import 'rich_clipboard_stub.dart'
    if (dart.library.js_interop) 'rich_clipboard_web.dart';

export 'clipboard_snapshot.dart';
export 'rich_clipboard_stub.dart'
    if (dart.library.js_interop) 'rich_clipboard_web.dart';

/// Reads `text/html` from the clipboard, or null.
Future<String?> readClipboardHtml() async => (await readClipboard()).html;

/// Reads `text/plain`, using the same single read as [readClipboard] on web
/// and Flutter's [Clipboard] elsewhere.
Future<String?> readClipboardText() async {
  final clip = await readClipboard();
  if (clip.isAvailable) return clip.text;
  return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}
