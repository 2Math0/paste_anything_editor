import 'package:flutter/material.dart';

import 'math_codec.dart';
import 'math_symbols.dart';
import 'math_view.dart';

/// What the user chose in [MathInputPanel] / [MathInputDialog].
sealed class MathInsertion {
  const MathInsertion();
}

class MathSymbolInsertion extends MathInsertion {
  const MathSymbolInsertion(this.char);
  final String char;
}

class MathFormulaInsertion extends MathInsertion {
  const MathFormulaInsertion(this.latex);
  final String latex;
}

/// Standalone math input: Unicode symbol palette + LaTeX formula editor with
/// live preview, templates and its own copy/paste.
///
/// Without callbacks it works as a copy tool: tapping a symbol or pressing
/// "Copy formula" puts it on the clipboard.
class MathInputPanel extends StatefulWidget {
  const MathInputPanel({
    super.key,
    this.initialLatex,
    this.onSymbol,
    this.onFormula,
  });

  final String? initialLatex;
  final ValueChanged<String>? onSymbol;
  final ValueChanged<String>? onFormula;

  @override
  State<MathInputPanel> createState() => _MathInputPanelState();
}

class _MathInputPanelState extends State<MathInputPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialLatex != null ? 1 : 0,
  );
  late final TextEditingController _latex =
      TextEditingController(text: widget.initialLatex ?? '');
  final FocusNode _latexFocus = FocusNode();

  @override
  void dispose() {
    _tabs.dispose();
    _latex.dispose();
    _latexFocus.dispose();
    super.dispose();
  }

  String get _formula => MathCodec.normalizeLatex(_latex.text);

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSymbolTap(MathSymbol symbol) async {
    final onSymbol = widget.onSymbol;
    if (onSymbol != null) {
      onSymbol(symbol.char);
      return;
    }
    await MathCodec.copySymbol(symbol.char);
    _toast('Copied ${symbol.char}');
  }

  Future<void> _copySymbol(MathSymbol symbol) async {
    await MathCodec.copySymbol(symbol.char);
    _toast('Copied ${symbol.char}');
  }

  void _insertIntoFormula(String snippet) {
    final value = _latex.value;
    final sel = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final needsSpace =
        snippet.startsWith(r'\') && RegExp(r'[a-zA-Z]$').hasMatch(snippet);
    final insert = needsSpace ? '$snippet ' : snippet;
    _latex.value = TextEditingValue(
      text: value.text.replaceRange(sel.start, sel.end, insert),
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _latexFocus.requestFocus();
  }

  Future<void> _pasteFormula() async {
    final latex = await MathCodec.readFormulaFromClipboard();
    if (latex == null || latex.isEmpty) {
      _toast('No formula on the clipboard');
      return;
    }
    _insertIntoFormula(latex);
  }

  Future<void> _copyFormula() async {
    if (_formula.isEmpty) return;
    await MathCodec.copyFormula(_formula);
    _toast('Formula copied');
  }

  Future<void> _copyLatex() async {
    if (_formula.isEmpty) return;
    await MathCodec.copyLatex(_formula);
    _toast('LaTeX copied');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Symbols'),
            Tab(icon: Icon(Icons.functions), text: 'Formula'),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildSymbolsTab(),
              _buildFormulaTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolsTab() {
    final hint = widget.onSymbol != null
        ? 'Tap to insert · long-press to copy'
        : 'Tap to copy';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Expanded(
          child: _SymbolPalette(
            onTap: _onSymbolTap,
            onLongPress: _copySymbol,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in kMathTemplates)
              Tooltip(
                message: '${t.tooltip}\n${t.latex}',
                child: ActionChip(
                  label: Text(t.label),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _insertIntoFormula(t.latex),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _latex,
          focusNode: _latexFocus,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: InputDecoration(
            labelText: 'LaTeX',
            hintText: r'e.g. x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Paste formula',
              icon: const Icon(Icons.content_paste),
              onPressed: _pasteFormula,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _latex,
            builder: (context, value, _) {
              final latex = MathCodec.normalizeLatex(value.text);
              if (latex.isEmpty) {
                return Text(
                  'Preview',
                  style: TextStyle(color: Colors.grey.shade500),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: MathFormulaView(
                  latex,
                  display: true,
                  textStyle: const TextStyle(fontSize: 20),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SymbolPalette(
            compact: true,
            onTap: (s) => _insertIntoFormula(s.latexOrChar),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _latex,
          builder: (context, value, _) {
            final hasFormula = MathCodec.normalizeLatex(value.text).isNotEmpty;
            return Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: hasFormula ? _copyLatex : null,
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('Copy LaTeX'),
                ),
                OutlinedButton.icon(
                  onPressed: hasFormula ? _copyFormula : null,
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: const Text('Copy formula'),
                ),
                if (widget.onFormula != null)
                  FilledButton.icon(
                    onPressed: hasFormula
                        ? () => widget.onFormula!(_formula)
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Insert'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SymbolPalette extends StatefulWidget {
  const _SymbolPalette({
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final ValueChanged<MathSymbol> onTap;
  final ValueChanged<MathSymbol>? onLongPress;
  final bool compact;

  @override
  State<_SymbolPalette> createState() => _SymbolPaletteState();
}

class _SymbolPaletteState extends State<_SymbolPalette> {
  int _group = 0;

  @override
  Widget build(BuildContext context) {
    final group = kMathSymbolGroups[_group];
    final size = widget.compact ? 34.0 : 44.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kMathSymbolGroups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(kMathSymbolGroups[i].title),
              visualDensity: VisualDensity.compact,
              selected: i == _group,
              onSelected: (_) => setState(() => _group = i),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final s in group.symbols)
                  Tooltip(
                    message: s.latex == null ? s.name : '${s.name}  ${s.latex}',
                    waitDuration: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => widget.onTap(s),
                        onLongPress: widget.onLongPress == null
                            ? null
                            : () => widget.onLongPress!(s),
                        child: Text(
                          s.char,
                          style: TextStyle(fontSize: widget.compact ? 16 : 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// [MathInputPanel] in a dialog. Returns the chosen symbol or formula, or
/// null if closed.
abstract final class MathInputDialog {
  static Future<MathInsertion?> show(
    BuildContext context, {
    String? initialLatex,
  }) {
    return showDialog<MathInsertion>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Math',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Expanded(
                  child: MathInputPanel(
                    initialLatex: initialLatex,
                    onSymbol: (c) =>
                        Navigator.pop(ctx, MathSymbolInsertion(c)),
                    onFormula: (l) =>
                        Navigator.pop(ctx, MathFormulaInsertion(l)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
