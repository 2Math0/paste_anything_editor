import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Provides [FlutterQuillLocalizations] to [child] when the app didn't add
/// `FlutterQuillLocalizations.delegate`, so Quill's toolbar doesn't throw
/// `MissingFlutterQuillLocalizationException`. Uses the app locale, or
/// English when Quill doesn't support it.
class QuillLocalizationsScope extends StatelessWidget {
  const QuillLocalizationsScope({super.key, required this.child});

  final Widget child;

  static const _fallbackLocale = Locale('en');

  @override
  Widget build(BuildContext context) {
    if (FlutterQuillLocalizations.of(context) != null) return child;
    final locale = Localizations.maybeLocaleOf(context) ?? _fallbackLocale;
    return Localizations.override(
      context: context,
      locale: FlutterQuillLocalizations.delegate.isSupported(locale)
          ? locale
          : _fallbackLocale,
      delegates: const [FlutterQuillLocalizations.delegate],
      child: child,
    );
  }
}
