import 'clipboard_stub.dart' if (dart.library.js_interop) 'clipboard_web.dart'
    as impl;
import 'pae_clip.dart';

/// Browser async Clipboard API access.
///
/// The first read shows the browser's permission prompt, which takes focus
/// from the page; [read] waits for focus to return and retries once.
abstract final class PaeClipboard {
  /// Reads `text/html`, `text/plain` and the first `image/*` item with a
  /// single Clipboard API call.
  static Future<PaeClip> read() => impl.readClip();

  /// `text/html` on the clipboard, or null.
  static Future<String?> readHtml() async => (await read()).html;

  /// `text/plain` on the clipboard, or null.
  static Future<String?> readText() async {
    final clip = await read();
    return clip.isAvailable ? clip.text : impl.readPlainText();
  }

  /// Writes [html] as `text/html` and [plainText] (defaults to [html]) as
  /// `text/plain`. Returns false if the browser rejected the write.
  static Future<bool> writeHtml(String html, {String? plainText}) =>
      impl.writeHtml(html, plainText ?? html);

  /// Writes [text] as `text/plain`. Returns false if the browser rejected
  /// the write.
  static Future<bool> writeText(String text) => impl.writeText(text);

  /// Waits until the page has focus again (e.g. after a permission prompt).
  /// Returns false on timeout.
  static Future<bool> waitForFocus({
    Duration timeout = const Duration(seconds: 3),
  }) =>
      impl.waitForFocus(timeout);
}
