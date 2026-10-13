import 'clipboard_snapshot.dart';

/// Rich clipboard access is web-only for now; other platforms fall back to
/// Flutter's plain-text clipboard.
Future<ClipboardSnapshot> readClipboard() async => ClipboardSnapshot.empty;

Future<String?> readClipboardHtml() async => null;

Future<bool> writeClipboardHtml(String html, {required String plainText}) async =>
    false;
