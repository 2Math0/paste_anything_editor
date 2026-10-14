import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:paste_anything/paste_anything.dart';

import '../codec/pae_quill_codec.dart';
import '../math/pae_math_view.dart';

/// Renders a [PaeQuillCodec.tableEmbedType] block embed with edit / remove
/// actions.
class PaeTableEmbedBuilder extends EmbedBuilder {
  const PaeTableEmbedBuilder();

  @override
  String get key => PaeQuillCodec.tableEmbedType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final html = embedContext.node.value.data.toString();
    final controller = embedContext.controller;
    final offset = embedContext.node.documentOffset;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: HtmlWidget(
              html,
              textStyle: embedContext.textStyle,
              customWidgetBuilder: paeMathHtmlBuilder,
            ),
          ),
          if (!embedContext.readOnly)
            Positioned(
              top: 0,
              right: 0,
              child: _EmbedActions(
                children: [
                  IconButton(
                    tooltip: 'Edit table HTML',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final updated = await _editTableHtml(context, html);
                      if (updated == null) return;
                      controller.replaceText(
                        offset,
                        1,
                        BlockEmbed(PaeQuillCodec.tableEmbedType, updated),
                        null,
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Remove table',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.replaceText(
                      offset,
                      1,
                      '',
                      TextSelection.collapsed(offset: offset),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<String?> _editTableHtml(BuildContext context, String html) {
    final textController = TextEditingController(text: html);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit table HTML'),
        content: SizedBox(
          width: 640,
          child: TextField(
            controller: textController,
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final sanitized =
                  PaeHtml.sanitizeTableSource(textController.text);
              if (sanitized != null) Navigator.pop(ctx, sanitized);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EmbedActions extends StatelessWidget {
  const _EmbedActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 1,
      borderRadius: BorderRadius.circular(6),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
