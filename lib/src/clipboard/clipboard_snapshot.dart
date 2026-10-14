import 'dart:typed_data';

/// A bitmap read from the system clipboard.
class ClipboardImage {
  const ClipboardImage(this.bytes, this.mimeType);

  final Uint8List bytes;

  /// e.g. `image/png`.
  final String mimeType;
}

/// The flavors of the system clipboard visible to the app, read in one go.
class ClipboardSnapshot {
  const ClipboardSnapshot({
    this.html,
    this.text,
    this.image,
    this.isAvailable = true,
  });

  /// Returned when the rich clipboard can't be read (non-web platform,
  /// permission denied, unsupported browser).
  static const unavailable = ClipboardSnapshot(isAvailable: false);

  /// `text/html` (Word, Excel, Google Docs, web pages, this editor).
  final String? html;

  /// `text/plain`.
  final String? text;

  /// First `image/*` item (screenshots, "Copy image" in a browser).
  final ClipboardImage? image;

  /// False when the clipboard couldn't be read at all; callers should fall
  /// back to Flutter's plain-text `Clipboard`.
  final bool isAvailable;
}
