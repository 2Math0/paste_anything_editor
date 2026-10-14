import 'dart:convert';
import 'dart:typed_data';

/// A bitmap read from the system clipboard.
class PaeImage {
  const PaeImage(this.bytes, this.mimeType);

  final Uint8List bytes;

  /// e.g. `image/png`.
  final String mimeType;

  /// `data:<mimeType>;base64,...`, ready for an `<img src>`.
  String toDataUri() => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

/// The clipboard flavors visible to the page, read in one go.
class PaeClip {
  const PaeClip({
    this.html,
    this.text,
    this.image,
    this.isAvailable = true,
  });

  /// Returned when the clipboard can't be read (permission denied,
  /// unsupported browser, non-web platform).
  static const unavailable = PaeClip(isAvailable: false);

  /// `text/html` (Word, Excel, Google Docs, web pages, rich editors).
  final String? html;

  /// `text/plain`.
  final String? text;

  /// First `image/*` item (screenshots, "Copy image" in a browser).
  final PaeImage? image;

  /// False when the clipboard couldn't be read at all.
  final bool isAvailable;

  bool get isEmpty =>
      (html == null || html!.trim().isEmpty) &&
      (text == null || text!.isEmpty) &&
      image == null;
}
