import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:paste_anything/paste_anything.dart';

import '../codec/pae_quill_codec.dart';
import 'pae_math_dialog.dart';
import 'pae_math_theme.dart';
import 'pae_math_view.dart';

/// Inline Quill embed rendering a [PaeQuillCodec.mathEmbedType] formula.
/// Tap to edit; the menu copies or removes it.
class PaeMathEmbedBuilder extends EmbedBuilder {
  const PaeMathEmbedBuilder({
    this.dialogTheme,
    this.dialogLabels = const PaeMathLabels(),
  });

  /// Styles the edit dialog; see [PaeMathDialog.show].
  final PaeMathTheme? dialogTheme;
  final PaeMathLabels dialogLabels;

  @override
  String get key => PaeQuillCodec.mathEmbedType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final snippet =
        PaeMathSnippet.fromEmbedValue(embedContext.node.value.data);
    final latex = snippet.latex;
    final controller = embedContext.controller;
    final offset = embedContext.node.documentOffset;
    final formula = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PaeMathView(
        latex,
        display: snippet.display,
        textStyle: embedContext.textStyle,
      ),
    );

    if (embedContext.readOnly) return formula;

    Future<void> edit() async {
      final result = await PaeMathDialog.show(
        context,
        initialLatex: latex,
        theme: dialogTheme,
        labels: dialogLabels,
        showSymbolsTab: false,
      );
      if (result is PaeMathFormulaInsertion) {
        final updated = PaeMath.parseSnippet(
          result.latex,
          display: snippet.display,
        );
        controller.replaceText(
          offset,
          1,
          Embeddable(PaeQuillCodec.mathEmbedType, updated.toEmbedValue()),
          null,
        );
      }
    }

    return Tooltip(
      message: latex,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: edit,
          onSecondaryTapDown: (details) async {
            final action = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy,
              ),
              items: const [
                PopupMenuItem(value: 'edit', child: Text('Edit formula')),
                PopupMenuItem(value: 'copy', child: Text('Copy formula')),
                PopupMenuItem(value: 'latex', child: Text('Copy LaTeX')),
                PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            );
            switch (action) {
              case 'edit':
                await edit();
              case 'copy':
                await PaeMath.copyFormula(latex, display: snippet.display);
              case 'latex':
                await PaeClipboard.writeText(latex);
              case 'remove':
                controller.replaceText(
                  offset,
                  1,
                  '',
                  TextSelection.collapsed(offset: offset),
                );
            }
          },
          child: formula,
        ),
      ),
    );
  }
}
