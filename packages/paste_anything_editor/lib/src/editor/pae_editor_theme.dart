import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colors, sizes and snackbar chrome of [PaeEditor].
///
/// Every field is optional. Unset values come from the app [ColorScheme].
/// Set app-wide with `ThemeData(extensions: [PaeEditorTheme(...)])` and/or
/// per editor via `PaeEditor(editorTheme: ...)`.
@immutable
class PaeEditorTheme extends ThemeExtension<PaeEditorTheme> {
  const PaeEditorTheme({
    this.seedColor,
    this.colorScheme,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.toolbarBackgroundColor,
    this.contentLabelStyle,
    this.copyPasteBackgroundColor,
    this.copyPasteBorderColor,
    this.copyPasteBorderRadius,
    this.copyFormattedColor,
    this.pasteFormattedColor,
    this.copyPlainColor,
    this.pastePlainColor,
    this.snackBarBackgroundColor,
    this.snackBarErrorBackgroundColor,
    this.snackBarForegroundColor,
    this.snackBarErrorForegroundColor,
    this.snackBarDuration,
    this.snackBarBehavior,
    this.snackBarMargin,
    this.snackBarPadding,
    this.snackBarShape,
    this.snackBarElevation,
    this.snackBarWidth,
  });

  final Color? seedColor;
  final ColorScheme? colorScheme;

  /// Editor frame.
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;

  /// Quill toolbar strip behind the formatting buttons.
  final Color? toolbarBackgroundColor;

  final TextStyle? contentLabelStyle;

  /// Compact copy/paste chip row.
  final Color? copyPasteBackgroundColor;
  final Color? copyPasteBorderColor;
  final double? copyPasteBorderRadius;
  final Color? copyFormattedColor;
  final Color? pasteFormattedColor;
  final Color? copyPlainColor;
  final Color? pastePlainColor;

  /// Default [SnackBar] look when [PaeEditor.onNotify] is null.
  final Color? snackBarBackgroundColor;
  final Color? snackBarErrorBackgroundColor;
  final Color? snackBarForegroundColor;
  final Color? snackBarErrorForegroundColor;
  final Duration? snackBarDuration;
  final SnackBarBehavior? snackBarBehavior;
  final EdgeInsetsGeometry? snackBarMargin;
  final EdgeInsetsGeometry? snackBarPadding;
  final ShapeBorder? snackBarShape;
  final double? snackBarElevation;
  final double? snackBarWidth;

  factory PaeEditorTheme.fallback(ColorScheme scheme) {
    return PaeEditorTheme(
      colorScheme: scheme,
      borderColor: scheme.outlineVariant,
      borderWidth: 1,
      borderRadius: 8,
      toolbarBackgroundColor: scheme.surfaceContainerLow,
      contentLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: scheme.onSurface,
      ),
      copyPasteBackgroundColor: scheme.surfaceContainerLow,
      copyPasteBorderColor: scheme.outlineVariant,
      copyPasteBorderRadius: 8,
      copyFormattedColor: scheme.primary,
      pasteFormattedColor: scheme.tertiary,
      copyPlainColor: scheme.secondary,
      pastePlainColor: scheme.error,
      snackBarBackgroundColor: scheme.inverseSurface,
      snackBarErrorBackgroundColor: scheme.error,
      snackBarForegroundColor: scheme.onInverseSurface,
      snackBarErrorForegroundColor: scheme.onError,
      snackBarDuration: const Duration(seconds: 3),
      snackBarBehavior: SnackBarBehavior.floating,
      snackBarMargin: const EdgeInsets.all(12),
      snackBarElevation: 4,
    );
  }

  static PaeEditorTheme resolve(
    BuildContext context, [
    PaeEditorTheme? override,
  ]) {
    final base = Theme.of(context);
    final partial =
        (base.extension<PaeEditorTheme>() ?? const PaeEditorTheme())
            .merge(override);
    final seed = partial.seedColor;
    final scheme = partial.colorScheme ??
        (seed != null
            ? ColorScheme.fromSeed(seedColor: seed, brightness: base.brightness)
            : base.colorScheme);
    return PaeEditorTheme.fallback(scheme)
        .merge(partial.copyWith(colorScheme: scheme));
  }

  PaeEditorTheme merge(PaeEditorTheme? other) {
    if (other == null) return this;
    return copyWith(
      seedColor: other.seedColor,
      colorScheme: other.colorScheme,
      borderColor: other.borderColor,
      borderWidth: other.borderWidth,
      borderRadius: other.borderRadius,
      toolbarBackgroundColor: other.toolbarBackgroundColor,
      contentLabelStyle: contentLabelStyle?.merge(other.contentLabelStyle) ??
          other.contentLabelStyle,
      copyPasteBackgroundColor: other.copyPasteBackgroundColor,
      copyPasteBorderColor: other.copyPasteBorderColor,
      copyPasteBorderRadius: other.copyPasteBorderRadius,
      copyFormattedColor: other.copyFormattedColor,
      pasteFormattedColor: other.pasteFormattedColor,
      copyPlainColor: other.copyPlainColor,
      pastePlainColor: other.pastePlainColor,
      snackBarBackgroundColor: other.snackBarBackgroundColor,
      snackBarErrorBackgroundColor: other.snackBarErrorBackgroundColor,
      snackBarForegroundColor: other.snackBarForegroundColor,
      snackBarErrorForegroundColor: other.snackBarErrorForegroundColor,
      snackBarDuration: other.snackBarDuration,
      snackBarBehavior: other.snackBarBehavior,
      snackBarMargin: other.snackBarMargin,
      snackBarPadding: other.snackBarPadding,
      snackBarShape: other.snackBarShape,
      snackBarElevation: other.snackBarElevation,
      snackBarWidth: other.snackBarWidth,
    );
  }

  @override
  PaeEditorTheme copyWith({
    Color? seedColor,
    ColorScheme? colorScheme,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? toolbarBackgroundColor,
    TextStyle? contentLabelStyle,
    Color? copyPasteBackgroundColor,
    Color? copyPasteBorderColor,
    double? copyPasteBorderRadius,
    Color? copyFormattedColor,
    Color? pasteFormattedColor,
    Color? copyPlainColor,
    Color? pastePlainColor,
    Color? snackBarBackgroundColor,
    Color? snackBarErrorBackgroundColor,
    Color? snackBarForegroundColor,
    Color? snackBarErrorForegroundColor,
    Duration? snackBarDuration,
    SnackBarBehavior? snackBarBehavior,
    EdgeInsetsGeometry? snackBarMargin,
    EdgeInsetsGeometry? snackBarPadding,
    ShapeBorder? snackBarShape,
    double? snackBarElevation,
    double? snackBarWidth,
  }) {
    return PaeEditorTheme(
      seedColor: seedColor ?? this.seedColor,
      colorScheme: colorScheme ?? this.colorScheme,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      toolbarBackgroundColor:
          toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      contentLabelStyle: contentLabelStyle ?? this.contentLabelStyle,
      copyPasteBackgroundColor:
          copyPasteBackgroundColor ?? this.copyPasteBackgroundColor,
      copyPasteBorderColor: copyPasteBorderColor ?? this.copyPasteBorderColor,
      copyPasteBorderRadius:
          copyPasteBorderRadius ?? this.copyPasteBorderRadius,
      copyFormattedColor: copyFormattedColor ?? this.copyFormattedColor,
      pasteFormattedColor: pasteFormattedColor ?? this.pasteFormattedColor,
      copyPlainColor: copyPlainColor ?? this.copyPlainColor,
      pastePlainColor: pastePlainColor ?? this.pastePlainColor,
      snackBarBackgroundColor:
          snackBarBackgroundColor ?? this.snackBarBackgroundColor,
      snackBarErrorBackgroundColor:
          snackBarErrorBackgroundColor ?? this.snackBarErrorBackgroundColor,
      snackBarForegroundColor:
          snackBarForegroundColor ?? this.snackBarForegroundColor,
      snackBarErrorForegroundColor:
          snackBarErrorForegroundColor ?? this.snackBarErrorForegroundColor,
      snackBarDuration: snackBarDuration ?? this.snackBarDuration,
      snackBarBehavior: snackBarBehavior ?? this.snackBarBehavior,
      snackBarMargin: snackBarMargin ?? this.snackBarMargin,
      snackBarPadding: snackBarPadding ?? this.snackBarPadding,
      snackBarShape: snackBarShape ?? this.snackBarShape,
      snackBarElevation: snackBarElevation ?? this.snackBarElevation,
      snackBarWidth: snackBarWidth ?? this.snackBarWidth,
    );
  }

  @override
  PaeEditorTheme lerp(covariant PaeEditorTheme? other, double t) {
    if (other == null) return this;
    Color? c(Color? a, Color? b) => Color.lerp(a, b, t);
    double? d(double? a, double? b) => lerpDouble(a, b, t);
    return PaeEditorTheme(
      seedColor: c(seedColor, other.seedColor),
      colorScheme: t < 0.5 ? colorScheme : other.colorScheme,
      borderColor: c(borderColor, other.borderColor),
      borderWidth: d(borderWidth, other.borderWidth),
      borderRadius: d(borderRadius, other.borderRadius),
      toolbarBackgroundColor:
          c(toolbarBackgroundColor, other.toolbarBackgroundColor),
      contentLabelStyle:
          TextStyle.lerp(contentLabelStyle, other.contentLabelStyle, t),
      copyPasteBackgroundColor:
          c(copyPasteBackgroundColor, other.copyPasteBackgroundColor),
      copyPasteBorderColor: c(copyPasteBorderColor, other.copyPasteBorderColor),
      copyPasteBorderRadius:
          d(copyPasteBorderRadius, other.copyPasteBorderRadius),
      copyFormattedColor: c(copyFormattedColor, other.copyFormattedColor),
      pasteFormattedColor: c(pasteFormattedColor, other.pasteFormattedColor),
      copyPlainColor: c(copyPlainColor, other.copyPlainColor),
      pastePlainColor: c(pastePlainColor, other.pastePlainColor),
      snackBarBackgroundColor:
          c(snackBarBackgroundColor, other.snackBarBackgroundColor),
      snackBarErrorBackgroundColor:
          c(snackBarErrorBackgroundColor, other.snackBarErrorBackgroundColor),
      snackBarForegroundColor:
          c(snackBarForegroundColor, other.snackBarForegroundColor),
      snackBarErrorForegroundColor:
          c(snackBarErrorForegroundColor, other.snackBarErrorForegroundColor),
      snackBarDuration: t < 0.5 ? snackBarDuration : other.snackBarDuration,
      snackBarBehavior: t < 0.5 ? snackBarBehavior : other.snackBarBehavior,
      snackBarMargin: EdgeInsetsGeometry.lerp(
        snackBarMargin,
        other.snackBarMargin,
        t,
      ),
      snackBarPadding: EdgeInsetsGeometry.lerp(
        snackBarPadding,
        other.snackBarPadding,
        t,
      ),
      snackBarShape: t < 0.5 ? snackBarShape : other.snackBarShape,
      snackBarElevation: d(snackBarElevation, other.snackBarElevation),
      snackBarWidth: d(snackBarWidth, other.snackBarWidth),
    );
  }
}

/// User-visible strings of [PaeEditor] (toasts, tooltips, labels).
@immutable
class PaeEditorLabels {
  const PaeEditorLabels({
    this.contentLabel = 'Content',
    this.copiedWithFormatting = 'Copied with formatting',
    this.copiedAsPlainText = 'Copied as plain text',
    this.pastedWithFormatting = 'Pasted with formatting',
    this.pastedAsPlainText = 'Pasted as plain text',
    this.noContentToCopy = 'No content to copy',
    this.nothingToPaste = 'Nothing to paste',
    this.failedToCopy = 'Failed to copy',
    this.failedToPaste = 'Failed to paste',
    this.copyFormattedTooltip = 'Copy with formatting',
    this.pasteFormattedTooltip = 'Paste with formatting',
    this.copyPlainTooltip = 'Copy as plain text',
    this.pastePlainTooltip = 'Paste as plain text',
    this.cannotFormatFormula =
        "Formatting can't be applied to LaTeX formulas",
  });

  final String contentLabel;
  final String copiedWithFormatting;
  final String copiedAsPlainText;
  final String pastedWithFormatting;
  final String pastedAsPlainText;
  final String noContentToCopy;
  final String nothingToPaste;
  final String failedToCopy;
  final String failedToPaste;
  final String copyFormattedTooltip;
  final String pasteFormattedTooltip;
  final String copyPlainTooltip;
  final String pastePlainTooltip;

  /// Toast when the user tries to style a selected LaTeX formula.
  final String cannotFormatFormula;
}
