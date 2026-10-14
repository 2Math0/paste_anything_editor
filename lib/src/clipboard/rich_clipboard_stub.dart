import 'clipboard_snapshot.dart';

/// Rich clipboard access is web-only for now; other platforms fall back to
/// Flutter's plain-text clipboard.
Future<ClipboardSnapshot> readClipboard() async => ClipboardSnapshot.unavailable;

Future<bool> waitForDocumentFocus({
  Duration timeout = const Duration(seconds: 3),
}) async =>
    true;

Future<bool> writeClipboardHtml(String html, {required String plainText}) async =>
    false;
