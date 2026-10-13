import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'math_codec.dart';
import 'math_input_panel.dart';
import 'math_view.dart';

/// Inline Quill embed rendering a [MathCodec.embedType] formula.
/// Tap to edit; the menu copies or removes it.
class MathFormulaEmbedBuilder extends EmbedBuilder {
  const MathFormulaEmbedBuilder();

  @override
  String get key => MathCodec.embedType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final latex = embedContext.node.value.data.toString();
    final controller = embedContext.controller;
    final offset = embedContext.node.documentOffset;
    final formula = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MathFormulaView(latex, textStyle: embedContext.textStyle),
    );

    if (embedContext.readOnly) return formula;

    Future<void> edit() async {
      final result = await MathInputDialog.show(context, initialLatex: latex);
      if (result is MathFormulaInsertion) {
        controller.replaceText(
          offset,
          1,
          Embeddable(MathCodec.embedType, result.latex),
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
                await MathCodec.copyFormula(latex);
              case 'latex':
                await MathCodec.copyLatex(latex);
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
