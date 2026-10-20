import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colors, shapes and sizes of [PaeMathPanel] / [PaeMathDialog].
///
/// Every field is optional. Unset values come from the app's [ColorScheme]
/// (or one generated from [seedColor]), so the panel matches Material 3 out
/// of the box. Set it app-wide with `ThemeData(extensions: [PaeMathTheme(...)])`
/// and/or per use via the `theme:` parameter; per-use values win.
///
/// Shape / chrome example:
/// ```dart
/// Theme(
///   data: Theme.of(context).copyWith(
///     extensions: [
///       PaeMathTheme(
///         dialogBorderRadius: 16,
///         dialogShape: RoundedRectangleBorder(
///           borderRadius: BorderRadius.circular(16),
///           side: BorderSide(color: Colors.black12),
///         ),
///         dialogElevation: 10,
///         dialogMaxWidth: 640,
///       ),
///     ],
///   ),
///   child: child,
/// )
/// ```
@immutable
class PaeMathTheme extends ThemeExtension<PaeMathTheme> {
  const PaeMathTheme({
    this.seedColor,
    this.colorScheme,
    this.backgroundColor,
    this.headerColor,
    this.headerForegroundColor,
    this.titleTextStyle,
    this.tabIndicatorColor,
    this.tabSelectedColor,
    this.tabUnselectedColor,
    this.chipColor,
    this.chipSelectedColor,
    this.chipLabelColor,
    this.chipSelectedLabelColor,
    this.templateChipColor,
    this.templateChipLabelColor,
    this.symbolTileColor,
    this.symbolTileBorderColor,
    this.symbolColor,
    this.inputFillColor,
    this.latexTextStyle,
    this.previewBackgroundColor,
    this.previewBorderColor,
    this.previewFormulaColor,
    this.actionColor,
    this.actionForegroundColor,
    this.barrierColor,
    this.dialogBorderRadius,
    this.tileBorderRadius,
    this.chipBorderRadius,
    this.dialogElevation,
    this.dialogMaxWidth,
    this.dialogMaxHeight,
    this.dialogPadding,
    this.dialogInsetPadding,
    this.dialogShape,
    this.dialogBorderSide,
    this.dialogShadowColor,
    this.dialogClipBehavior,
    this.headerPadding,
    this.showHeaderIcon,
    this.previewMinHeight,
    this.symbolTileSize,
    this.compactSymbolTileSize,
    this.symbolFontSize,
    this.compactSymbolFontSize,
    this.previewFontSize,
    this.keyboardHeight,
    this.keyboardMaxWidth,
    this.keyboardBorderRadius,
  });

  /// Generates the [ColorScheme] when [colorScheme] is not given.
  final Color? seedColor;
  final ColorScheme? colorScheme;

  final Color? backgroundColor;
  final Color? headerColor;
  final Color? headerForegroundColor;
  final TextStyle? titleTextStyle;

  final Color? tabIndicatorColor;
  final Color? tabSelectedColor;
  final Color? tabUnselectedColor;

  /// Symbol category chips.
  final Color? chipColor;
  final Color? chipSelectedColor;
  final Color? chipLabelColor;
  final Color? chipSelectedLabelColor;

  /// Formula template chips (fraction, root, ...).
  final Color? templateChipColor;
  final Color? templateChipLabelColor;

  final Color? symbolTileColor;
  final Color? symbolTileBorderColor;
  final Color? symbolColor;

  final Color? inputFillColor;
  final TextStyle? latexTextStyle;

  final Color? previewBackgroundColor;
  final Color? previewBorderColor;
  final Color? previewFormulaColor;

  /// The primary "Insert" button.
  final Color? actionColor;
  final Color? actionForegroundColor;

  final Color? barrierColor;

  final double? dialogBorderRadius;
  final double? tileBorderRadius;
  final double? chipBorderRadius;
  final double? dialogElevation;
  final double? dialogMaxWidth;
  final double? dialogMaxHeight;
  final EdgeInsets? dialogPadding;
  final EdgeInsets? dialogInsetPadding;

  /// Full [ShapeBorder] for the dialog shell. When null, a
  /// [RoundedRectangleBorder] is built from [dialogBorderRadius] and
  /// [dialogBorderSide].
  final ShapeBorder? dialogShape;

  /// Used only when [dialogShape] is null.
  final BorderSide? dialogBorderSide;

  final Color? dialogShadowColor;

  /// Clip of the dialog material; defaults to [Clip.antiAlias].
  final Clip? dialogClipBehavior;

  final EdgeInsets? headerPadding;

  /// Leading ∑-style mark in the dialog header.
  final bool? showHeaderIcon;

  final double? previewMinHeight;

  final double? symbolTileSize;
  final double? compactSymbolTileSize;
  final double? symbolFontSize;
  final double? compactSymbolFontSize;
  final double? previewFontSize;

  /// [PaeMathKeyboard] height, max content width and top corner radius.
  final double? keyboardHeight;
  final double? keyboardMaxWidth;
  final double? keyboardBorderRadius;

  /// Fully populated defaults derived from [scheme].
  factory PaeMathTheme.fallback(ColorScheme scheme) {
    return PaeMathTheme(
      colorScheme: scheme,
      backgroundColor: scheme.surface,
      headerColor: scheme.surfaceContainerHigh,
      headerForegroundColor: scheme.onSurface,
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      tabIndicatorColor: scheme.primary,
      tabSelectedColor: scheme.primary,
      tabUnselectedColor: scheme.onSurfaceVariant,
      chipColor: scheme.surfaceContainerLow,
      chipSelectedColor: scheme.secondaryContainer,
      chipLabelColor: scheme.onSurfaceVariant,
      chipSelectedLabelColor: scheme.onSecondaryContainer,
      templateChipColor: scheme.tertiaryContainer,
      templateChipLabelColor: scheme.onTertiaryContainer,
      symbolTileColor: scheme.surfaceContainerLowest,
      symbolTileBorderColor: scheme.outlineVariant,
      symbolColor: scheme.onSurface,
      inputFillColor: scheme.surfaceContainerLowest,
      latexTextStyle: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: scheme.onSurface,
      ),
      previewBackgroundColor: scheme.surfaceContainerLow,
      previewBorderColor: scheme.outlineVariant,
      previewFormulaColor: scheme.onSurface,
      actionColor: scheme.primary,
      actionForegroundColor: scheme.onPrimary,
      barrierColor: Colors.black54,
      dialogBorderRadius: 24,
      tileBorderRadius: 8,
      chipBorderRadius: 8,
      dialogElevation: 8,
      dialogMaxWidth: 720,
      dialogMaxHeight: 640,
      dialogPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      dialogInsetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      dialogBorderSide: BorderSide.none,
      dialogShadowColor: Colors.black26,
      dialogClipBehavior: Clip.antiAlias,
      headerPadding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      showHeaderIcon: true,
      previewMinHeight: 72,
      symbolTileSize: 44,
      compactSymbolTileSize: 34,
      symbolFontSize: 20,
      compactSymbolFontSize: 16,
      previewFontSize: 20,
      keyboardHeight: 240,
      keyboardMaxWidth: 1200,
      keyboardBorderRadius: 20,
    );
  }

  /// Default seed when neither [seedColor] nor [colorScheme] is set — matches
  /// the teal look of the standalone math dialog.
  static const Color defaultSeedColor = Color(0xFF009688); // Colors.teal

  /// App-wide extension merged with [override], filled with defaults from
  /// the resulting color scheme.
  ///
  /// When no [colorScheme] / [seedColor] is provided (and the app extension
  /// also omits them), [defaultSeedColor] is used so the dialog and keyboard
  /// look the same out of the box.
  static PaeMathTheme resolve(BuildContext context, [PaeMathTheme? override]) {
    final base = Theme.of(context);
    final partial =
        (base.extension<PaeMathTheme>() ?? const PaeMathTheme()).merge(override);
    final seed = partial.seedColor ?? defaultSeedColor;
    final scheme = partial.colorScheme ??
        ColorScheme.fromSeed(seedColor: seed, brightness: base.brightness);
    return PaeMathTheme.fallback(scheme)
        .merge(partial.copyWith(colorScheme: scheme, seedColor: seed));
  }

  /// Effective dialog outline for [PaeMathDialog].
  ShapeBorder resolveDialogShape() {
    if (dialogShape != null) return dialogShape!;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialogBorderRadius ?? 24),
      side: dialogBorderSide ?? BorderSide.none,
    );
  }

  /// [other]'s non-null values replace this theme's.
  PaeMathTheme merge(PaeMathTheme? other) {
    if (other == null) return this;
    return copyWith(
      seedColor: other.seedColor,
      colorScheme: other.colorScheme,
      backgroundColor: other.backgroundColor,
      headerColor: other.headerColor,
      headerForegroundColor: other.headerForegroundColor,
      titleTextStyle: titleTextStyle?.merge(other.titleTextStyle) ??
          other.titleTextStyle,
      tabIndicatorColor: other.tabIndicatorColor,
      tabSelectedColor: other.tabSelectedColor,
      tabUnselectedColor: other.tabUnselectedColor,
      chipColor: other.chipColor,
      chipSelectedColor: other.chipSelectedColor,
      chipLabelColor: other.chipLabelColor,
      chipSelectedLabelColor: other.chipSelectedLabelColor,
      templateChipColor: other.templateChipColor,
      templateChipLabelColor: other.templateChipLabelColor,
      symbolTileColor: other.symbolTileColor,
      symbolTileBorderColor: other.symbolTileBorderColor,
      symbolColor: other.symbolColor,
      inputFillColor: other.inputFillColor,
      latexTextStyle: latexTextStyle?.merge(other.latexTextStyle) ??
          other.latexTextStyle,
      previewBackgroundColor: other.previewBackgroundColor,
      previewBorderColor: other.previewBorderColor,
      previewFormulaColor: other.previewFormulaColor,
      actionColor: other.actionColor,
      actionForegroundColor: other.actionForegroundColor,
      barrierColor: other.barrierColor,
      dialogBorderRadius: other.dialogBorderRadius,
      tileBorderRadius: other.tileBorderRadius,
      chipBorderRadius: other.chipBorderRadius,
      dialogElevation: other.dialogElevation,
      dialogMaxWidth: other.dialogMaxWidth,
      dialogMaxHeight: other.dialogMaxHeight,
      dialogPadding: other.dialogPadding,
      dialogInsetPadding: other.dialogInsetPadding,
      dialogShape: other.dialogShape,
      dialogBorderSide: other.dialogBorderSide,
      dialogShadowColor: other.dialogShadowColor,
      dialogClipBehavior: other.dialogClipBehavior,
      headerPadding: other.headerPadding,
      showHeaderIcon: other.showHeaderIcon,
      previewMinHeight: other.previewMinHeight,
      symbolTileSize: other.symbolTileSize,
      compactSymbolTileSize: other.compactSymbolTileSize,
      symbolFontSize: other.symbolFontSize,
      compactSymbolFontSize: other.compactSymbolFontSize,
      previewFontSize: other.previewFontSize,
      keyboardHeight: other.keyboardHeight,
      keyboardMaxWidth: other.keyboardMaxWidth,
      keyboardBorderRadius: other.keyboardBorderRadius,
    );
  }

  @override
  PaeMathTheme copyWith({
    Color? seedColor,
    ColorScheme? colorScheme,
    Color? backgroundColor,
    Color? headerColor,
    Color? headerForegroundColor,
    TextStyle? titleTextStyle,
    Color? tabIndicatorColor,
    Color? tabSelectedColor,
    Color? tabUnselectedColor,
    Color? chipColor,
    Color? chipSelectedColor,
    Color? chipLabelColor,
    Color? chipSelectedLabelColor,
    Color? templateChipColor,
    Color? templateChipLabelColor,
    Color? symbolTileColor,
    Color? symbolTileBorderColor,
    Color? symbolColor,
    Color? inputFillColor,
    TextStyle? latexTextStyle,
    Color? previewBackgroundColor,
    Color? previewBorderColor,
    Color? previewFormulaColor,
    Color? actionColor,
    Color? actionForegroundColor,
    Color? barrierColor,
    double? dialogBorderRadius,
    double? tileBorderRadius,
    double? chipBorderRadius,
    double? dialogElevation,
    double? dialogMaxWidth,
    double? dialogMaxHeight,
    EdgeInsets? dialogPadding,
    EdgeInsets? dialogInsetPadding,
    ShapeBorder? dialogShape,
    BorderSide? dialogBorderSide,
    Color? dialogShadowColor,
    Clip? dialogClipBehavior,
    EdgeInsets? headerPadding,
    bool? showHeaderIcon,
    double? previewMinHeight,
    double? symbolTileSize,
    double? compactSymbolTileSize,
    double? symbolFontSize,
    double? compactSymbolFontSize,
    double? previewFontSize,
    double? keyboardHeight,
    double? keyboardMaxWidth,
    double? keyboardBorderRadius,
  }) {
    return PaeMathTheme(
      seedColor: seedColor ?? this.seedColor,
      colorScheme: colorScheme ?? this.colorScheme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      headerColor: headerColor ?? this.headerColor,
      headerForegroundColor:
          headerForegroundColor ?? this.headerForegroundColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      tabIndicatorColor: tabIndicatorColor ?? this.tabIndicatorColor,
      tabSelectedColor: tabSelectedColor ?? this.tabSelectedColor,
      tabUnselectedColor: tabUnselectedColor ?? this.tabUnselectedColor,
      chipColor: chipColor ?? this.chipColor,
      chipSelectedColor: chipSelectedColor ?? this.chipSelectedColor,
      chipLabelColor: chipLabelColor ?? this.chipLabelColor,
      chipSelectedLabelColor:
          chipSelectedLabelColor ?? this.chipSelectedLabelColor,
      templateChipColor: templateChipColor ?? this.templateChipColor,
      templateChipLabelColor:
          templateChipLabelColor ?? this.templateChipLabelColor,
      symbolTileColor: symbolTileColor ?? this.symbolTileColor,
      symbolTileBorderColor:
          symbolTileBorderColor ?? this.symbolTileBorderColor,
      symbolColor: symbolColor ?? this.symbolColor,
      inputFillColor: inputFillColor ?? this.inputFillColor,
      latexTextStyle: latexTextStyle ?? this.latexTextStyle,
      previewBackgroundColor:
          previewBackgroundColor ?? this.previewBackgroundColor,
      previewBorderColor: previewBorderColor ?? this.previewBorderColor,
      previewFormulaColor: previewFormulaColor ?? this.previewFormulaColor,
      actionColor: actionColor ?? this.actionColor,
      actionForegroundColor:
          actionForegroundColor ?? this.actionForegroundColor,
      barrierColor: barrierColor ?? this.barrierColor,
      dialogBorderRadius: dialogBorderRadius ?? this.dialogBorderRadius,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      chipBorderRadius: chipBorderRadius ?? this.chipBorderRadius,
      dialogElevation: dialogElevation ?? this.dialogElevation,
      dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
      dialogMaxHeight: dialogMaxHeight ?? this.dialogMaxHeight,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      dialogInsetPadding: dialogInsetPadding ?? this.dialogInsetPadding,
      dialogShape: dialogShape ?? this.dialogShape,
      dialogBorderSide: dialogBorderSide ?? this.dialogBorderSide,
      dialogShadowColor: dialogShadowColor ?? this.dialogShadowColor,
      dialogClipBehavior: dialogClipBehavior ?? this.dialogClipBehavior,
      headerPadding: headerPadding ?? this.headerPadding,
      showHeaderIcon: showHeaderIcon ?? this.showHeaderIcon,
      previewMinHeight: previewMinHeight ?? this.previewMinHeight,
      symbolTileSize: symbolTileSize ?? this.symbolTileSize,
      compactSymbolTileSize:
          compactSymbolTileSize ?? this.compactSymbolTileSize,
      symbolFontSize: symbolFontSize ?? this.symbolFontSize,
      compactSymbolFontSize:
          compactSymbolFontSize ?? this.compactSymbolFontSize,
      previewFontSize: previewFontSize ?? this.previewFontSize,
      keyboardHeight: keyboardHeight ?? this.keyboardHeight,
      keyboardMaxWidth: keyboardMaxWidth ?? this.keyboardMaxWidth,
      keyboardBorderRadius: keyboardBorderRadius ?? this.keyboardBorderRadius,
    );
  }

  @override
  PaeMathTheme lerp(covariant PaeMathTheme? other, double t) {
    if (other == null) return this;
    Color? c(Color? a, Color? b) => Color.lerp(a, b, t);
    double? d(double? a, double? b) => lerpDouble(a, b, t);
    return PaeMathTheme(
      seedColor: c(seedColor, other.seedColor),
      colorScheme: t < 0.5 ? colorScheme : other.colorScheme,
      backgroundColor: c(backgroundColor, other.backgroundColor),
      headerColor: c(headerColor, other.headerColor),
      headerForegroundColor:
          c(headerForegroundColor, other.headerForegroundColor),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      tabIndicatorColor: c(tabIndicatorColor, other.tabIndicatorColor),
      tabSelectedColor: c(tabSelectedColor, other.tabSelectedColor),
      tabUnselectedColor: c(tabUnselectedColor, other.tabUnselectedColor),
      chipColor: c(chipColor, other.chipColor),
      chipSelectedColor: c(chipSelectedColor, other.chipSelectedColor),
      chipLabelColor: c(chipLabelColor, other.chipLabelColor),
      chipSelectedLabelColor:
          c(chipSelectedLabelColor, other.chipSelectedLabelColor),
      templateChipColor: c(templateChipColor, other.templateChipColor),
      templateChipLabelColor:
          c(templateChipLabelColor, other.templateChipLabelColor),
      symbolTileColor: c(symbolTileColor, other.symbolTileColor),
      symbolTileBorderColor:
          c(symbolTileBorderColor, other.symbolTileBorderColor),
      symbolColor: c(symbolColor, other.symbolColor),
      inputFillColor: c(inputFillColor, other.inputFillColor),
      latexTextStyle: TextStyle.lerp(latexTextStyle, other.latexTextStyle, t),
      previewBackgroundColor:
          c(previewBackgroundColor, other.previewBackgroundColor),
      previewBorderColor: c(previewBorderColor, other.previewBorderColor),
      previewFormulaColor: c(previewFormulaColor, other.previewFormulaColor),
      actionColor: c(actionColor, other.actionColor),
      actionForegroundColor:
          c(actionForegroundColor, other.actionForegroundColor),
      barrierColor: c(barrierColor, other.barrierColor),
      dialogBorderRadius: d(dialogBorderRadius, other.dialogBorderRadius),
      tileBorderRadius: d(tileBorderRadius, other.tileBorderRadius),
      chipBorderRadius: d(chipBorderRadius, other.chipBorderRadius),
      dialogElevation: d(dialogElevation, other.dialogElevation),
      dialogMaxWidth: d(dialogMaxWidth, other.dialogMaxWidth),
      dialogMaxHeight: d(dialogMaxHeight, other.dialogMaxHeight),
      dialogPadding: EdgeInsets.lerp(dialogPadding, other.dialogPadding, t),
      dialogInsetPadding:
          EdgeInsets.lerp(dialogInsetPadding, other.dialogInsetPadding, t),
      dialogShape: t < 0.5 ? dialogShape : other.dialogShape,
      dialogBorderSide: t < 0.5 ? dialogBorderSide : other.dialogBorderSide,
      dialogShadowColor: c(dialogShadowColor, other.dialogShadowColor),
      dialogClipBehavior:
          t < 0.5 ? dialogClipBehavior : other.dialogClipBehavior,
      headerPadding: EdgeInsets.lerp(headerPadding, other.headerPadding, t),
      showHeaderIcon: t < 0.5 ? showHeaderIcon : other.showHeaderIcon,
      previewMinHeight: d(previewMinHeight, other.previewMinHeight),
      symbolTileSize: d(symbolTileSize, other.symbolTileSize),
      compactSymbolTileSize:
          d(compactSymbolTileSize, other.compactSymbolTileSize),
      symbolFontSize: d(symbolFontSize, other.symbolFontSize),
      compactSymbolFontSize:
          d(compactSymbolFontSize, other.compactSymbolFontSize),
      previewFontSize: d(previewFontSize, other.previewFontSize),
      keyboardHeight: d(keyboardHeight, other.keyboardHeight),
      keyboardMaxWidth: d(keyboardMaxWidth, other.keyboardMaxWidth),
      keyboardBorderRadius:
          d(keyboardBorderRadius, other.keyboardBorderRadius),
    );
  }
}

/// Texts of [PaeMathPanel] / [PaeMathDialog], for localization or
/// wording changes.
@immutable
class PaeMathLabels {
  const PaeMathLabels({
    this.title = 'Math',
    this.close = 'Close',
    this.symbolsTab = 'Symbols',
    this.formulaTab = 'Formula',
    this.tapToInsertHint = 'Tap to insert · long-press to copy',
    this.tapToCopyHint = 'Tap to copy',
    this.latexLabel = 'LaTeX',
    this.latexHint = r'e.g. x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
    this.templatesLabel = 'Templates',
    this.pasteFormula = 'Paste formula',
    this.preview = 'Preview',
    this.copyLatex = 'Copy LaTeX',
    this.copyFormula = 'Copy formula',
    this.insert = 'Insert',
    this.copiedPrefix = 'Copied',
    this.formulaCopied = 'Formula copied',
    this.latexCopied = 'LaTeX copied',
    this.noFormulaOnClipboard = 'No formula on the clipboard',
    this.toolbarTooltip = 'Math symbols & formulas',
    this.cannotFormatFormula =
        "Formatting can't be applied to LaTeX formulas",
    this.keyboardTitle = 'Math',
    this.formulasCategory = 'Formulas',
    this.openLatexEditor = 'LaTeX editor',
    this.hideKeyboard = 'Hide math keyboard',
  });

  final String title;
  final String close;
  final String symbolsTab;
  final String formulaTab;
  final String tapToInsertHint;
  final String tapToCopyHint;
  final String latexLabel;
  final String latexHint;
  final String templatesLabel;
  final String pasteFormula;
  final String preview;
  final String copyLatex;
  final String copyFormula;
  final String insert;

  /// Shown as "`copiedPrefix` ∑" after copying a symbol.
  final String copiedPrefix;
  final String formulaCopied;
  final String latexCopied;
  final String noFormulaOnClipboard;

  /// Editor toolbar button.
  final String toolbarTooltip;

  /// Shown when the user tries to bold / resize / restyle a formula embed.
  final String cannotFormatFormula;

  /// [PaeMathKeyboard] texts.
  final String keyboardTitle;
  final String formulasCategory;
  final String openLatexEditor;
  final String hideKeyboard;
}
