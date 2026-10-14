import 'pae_clip.dart';

Future<PaeClip> readClip() async => PaeClip.unavailable;

Future<String?> readPlainText() async => null;

Future<bool> writeHtml(String html, String plainText) async => false;

Future<bool> writeText(String text) async => false;

Future<bool> waitForFocus(Duration timeout) async => true;
