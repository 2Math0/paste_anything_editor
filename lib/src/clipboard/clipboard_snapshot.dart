import 'dart:typed_data';

/// A bitmap read from the system clipboard.
class ClipboardImage {
  const ClipboardImage(this.bytes, this.mimeType);

  final Uint8List bytes;

  /// e.g. `image/png`.
  final String mimeType;
}

/// The rich flavors of the system clipboard visible to the app.
class ClipboardSnapshot {
  const ClipboardSnapshot({this.html, this.image});

  static const empty = ClipboardSnapshot();

  /// `text/html` (Word, Excel, Google Docs, web pages, this editor).
  final String? html;

  /// First `image/*` item (screenshots, "Copy image" in a browser).
  final ClipboardImage? image;
}
