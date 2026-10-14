import 'package:flutter/material.dart';
import 'package:paste_anything/paste_anything.dart';

import 'pae_math_theme.dart';
import 'pae_math_symbols.dart';
import 'pae_math_view.dart';

/// What the user chose in [PaeMathPanel] / [PaeMathDialog].
sealed class PaeMathInsertion {
  const PaeMathInsertion();
}

class PaeMathSymbolInsertion extends PaeMathInsertion {
  const PaeMathSymbolInsertion(this.char);
  final String char;
}

class PaeMathFormulaInsertion extends PaeMathInsertion {
  const PaeMathFormulaInsertion(this.latex);
  final String latex;
}

/// Standalone math input: Unicode symbol palette + LaTeX formula editor with
/// live preview, templates and its own copy/paste.
///
/// Without callbacks it works as a copy tool: tapping a symbol or pressing
/// "Copy formula" puts it on the clipboard.
class PaeMathPanel extends StatefulWidget {
  const PaeMathPanel({
    super.key,
    this.initialLatex,
    this.onSymbol,
    this.onFormula,
    this.theme,
    this.labels = const PaeMathLabels(),
    this.symbolGroups,
    this.templates,
    this.showSymbolsTab = true,
    this.showFormulaTab = true,
  }) : assert(showSymbolsTab || showFormulaTab);

  final String? initialLatex;
  final ValueChanged<String>? onSymbol;
  final ValueChanged<String>? onFormula;

  /// Overrides the app-wide [PaeMathTheme] extension for this panel.
  final PaeMathTheme? theme;
  final PaeMathLabels labels;

  /// Defaults to [kPaeMathSymbolGroups].
  final List<PaeMathSymbolGroup>? symbolGroups;

  /// Defaults to [kPaeMathTemplates].
  final List<PaeMathTemplate>? templates;

  final bool showSymbolsTab;
  final bool showFormulaTab;

  @override
  State<PaeMathPanel> createState() => _PaeMathPanelState();
}

class _PaeMathPanelState extends State<PaeMathPanel>
    with SingleTickerProviderStateMixin {
  late final bool _bothTabs = widget.showSymbolsTab && widget.showFormulaTab;
  late final TabController _tabs = TabController(
    length: _bothTabs ? 2 : 1,
    vsync: this,
    initialIndex: _bothTabs && widget.initialLatex != null ? 1 : 0,
  );
  late final TextEditingController _latex =
      TextEditingController(text: widget.initialLatex ?? '');
  final FocusNode _latexFocus = FocusNode();

  PaeMathLabels get _labels => widget.labels;
  List<PaeMathSymbolGroup> get _groups => widget.symbolGroups ?? kPaeMathSymbolGroups;

  @override
  void dispose() {
    _tabs.dispose();
    _latex.dispose();
    _latexFocus.dispose();
    super.dispose();
  }

  String get _formula => PaeMath.normalizeLatex(_latex.text);

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSymbolTap(PaeMathSymbol symbol) async {
    final onSymbol = widget.onSymbol;
    if (onSymbol != null) {
      onSymbol(symbol.char);
      return;
    }
    await _copySymbol(symbol);
  }

  Future<void> _copySymbol(PaeMathSymbol symbol) async {
    await PaeClipboard.writeText(symbol.char);
    _toast('${_labels.copiedPrefix} ${symbol.char}');
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
    final latex = await PaeMath.readFormula();
    if (latex == null || latex.isEmpty) {
      _toast(_labels.noFormulaOnClipboard);
      return;
    }
    _insertIntoFormula(latex);
  }

  Future<void> _copyFormula() async {
    if (_formula.isEmpty) return;
    await PaeMath.copyFormula(_formula);
    _toast(_labels.formulaCopied);
  }

  Future<void> _copyLatex() async {
    if (_formula.isEmpty) return;
    await PaeClipboard.writeText(_formula);
    _toast(_labels.latexCopied);
  }

  @override
  Widget build(BuildContext context) {
    final t = PaeMathTheme.resolve(context, widget.theme);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: t.colorScheme),
      child: Builder(builder: (context) => _buildContent(context, t)),
    );
  }

  Widget _buildContent(BuildContext context, PaeMathTheme t) {
    if (!_bothTabs) {
      return widget.showSymbolsTab
          ? _buildSymbolsTab(context, t)
          : _buildFormulaTab(context, t);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          indicatorColor: t.tabIndicatorColor,
          labelColor: t.tabSelectedColor,
          unselectedLabelColor: t.tabUnselectedColor,
          dividerColor: t.previewBorderColor,
          tabs: [
            Tab(icon: const Icon(Icons.grid_view), text: _labels.symbolsTab),
            Tab(icon: const Icon(Icons.functions), text: _labels.formulaTab),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildSymbolsTab(context, t),
              _buildFormulaTab(context, t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolsTab(BuildContext context, PaeMathTheme t) {
    final hint = widget.onSymbol != null
        ? _labels.tapToInsertHint
        : _labels.tapToCopyHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hint,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: t.tabUnselectedColor),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _SymbolPalette(
            groups: _groups,
            theme: t,
            onTap: _onSymbolTap,
            onLongPress: _copySymbol,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaTab(BuildContext context, PaeMathTheme t) {
    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.chipBorderRadius!),
    );
    final fieldRadius = BorderRadius.circular(t.tileBorderRadius!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tpl in widget.templates ?? kPaeMathTemplates)
              Tooltip(
                message: '${tpl.tooltip}\n${tpl.latex}',
                child: ActionChip(
                  label: Text(tpl.label),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: t.templateChipColor,
                  labelStyle: TextStyle(color: t.templateChipLabelColor),
                  side: BorderSide.none,
                  shape: chipShape,
                  onPressed: () => _insertIntoFormula(tpl.latex),
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
          style: t.latexTextStyle,
          decoration: InputDecoration(
            labelText: _labels.latexLabel,
            hintText: _labels.latexHint,
            filled: true,
            fillColor: t.inputFillColor,
            border: OutlineInputBorder(borderRadius: fieldRadius),
            enabledBorder: OutlineInputBorder(
              borderRadius: fieldRadius,
              borderSide: BorderSide(color: t.previewBorderColor!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: fieldRadius,
              borderSide: BorderSide(color: t.actionColor!, width: 2),
            ),
            suffixIcon: IconButton(
              tooltip: _labels.pasteFormula,
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
            border: Border.all(color: t.previewBorderColor!),
            borderRadius: fieldRadius,
            color: t.previewBackgroundColor,
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _latex,
            builder: (context, value, _) {
              final latex = PaeMath.normalizeLatex(value.text);
              if (latex.isEmpty) {
                return Text(
                  _labels.preview,
                  style: TextStyle(color: t.tabUnselectedColor),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: PaeMathView(
                  latex,
                  display: true,
                  textStyle: TextStyle(
                    fontSize: t.previewFontSize,
                    color: t.previewFormulaColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SymbolPalette(
            groups: _groups,
            theme: t,
            compact: true,
            onTap: (s) => _insertIntoFormula(s.latexOrChar),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _latex,
          builder: (context, value, _) {
            final hasFormula = PaeMath.normalizeLatex(value.text).isNotEmpty;
            return Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: hasFormula ? _copyLatex : null,
                  icon: const Icon(Icons.code, size: 18),
                  label: Text(_labels.copyLatex),
                ),
                OutlinedButton.icon(
                  onPressed: hasFormula ? _copyFormula : null,
                  icon: const Icon(Icons.content_copy, size: 18),
                  label: Text(_labels.copyFormula),
                ),
                if (widget.onFormula != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: t.actionColor,
                      foregroundColor: t.actionForegroundColor,
                    ),
                    onPressed: hasFormula
                        ? () => widget.onFormula!(_formula)
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_labels.insert),
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
    required this.groups,
    required this.theme,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final List<PaeMathSymbolGroup> groups;
  final PaeMathTheme theme;
  final ValueChanged<PaeMathSymbol> onTap;
  final ValueChanged<PaeMathSymbol>? onLongPress;
  final bool compact;

  @override
  State<_SymbolPalette> createState() => _SymbolPaletteState();
}

class _SymbolPaletteState extends State<_SymbolPalette> {
  int _group = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final groups = widget.groups;
    if (groups.isEmpty) return const SizedBox.shrink();
    final group = groups[_group.clamp(0, groups.length - 1)];
    final size = widget.compact ? t.compactSymbolTileSize! : t.symbolTileSize!;
    final fontSize =
        widget.compact ? t.compactSymbolFontSize! : t.symbolFontSize!;
    final tileShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.tileBorderRadius!),
      side: BorderSide(color: t.symbolTileBorderColor!),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final selected = i == _group;
              return ChoiceChip(
                label: Text(groups[i].title),
                visualDensity: VisualDensity.compact,
                selected: selected,
                backgroundColor: t.chipColor,
                selectedColor: t.chipSelectedColor,
                checkmarkColor: t.chipSelectedLabelColor,
                labelStyle: TextStyle(
                  color: selected ? t.chipSelectedLabelColor : t.chipLabelColor,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.chipBorderRadius!),
                ),
                onSelected: (_) => setState(() => _group = i),
              );
            },
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
                      child: Material(
                        color: t.symbolTileColor,
                        shape: tileShape,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => widget.onTap(s),
                          onLongPress: widget.onLongPress == null
                              ? null
                              : () => widget.onLongPress!(s),
                          child: Center(
                            child: Text(
                              s.char,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: t.symbolColor,
                              ),
                            ),
                          ),
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

/// [PaeMathPanel] in a dialog. Returns the chosen symbol or formula, or
/// null if closed.
abstract final class PaeMathDialog {
  static Future<PaeMathInsertion?> show(
    BuildContext context, {
    String? initialLatex,
    PaeMathTheme? theme,
    PaeMathLabels labels = const PaeMathLabels(),
    List<PaeMathSymbolGroup>? symbolGroups,
    List<PaeMathTemplate>? templates,
    bool showSymbolsTab = true,
    bool showFormulaTab = true,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    final t = PaeMathTheme.resolve(context, theme);
    final titleStyle = t.titleTextStyle!;
    return showDialog<PaeMathInsertion>(
      context: context,
      barrierColor: t.barrierColor,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (ctx) => Dialog(
        backgroundColor: t.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: t.dialogElevation,
        insetPadding: t.dialogInsetPadding,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.dialogBorderRadius!),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: t.dialogMaxWidth!,
            maxHeight: t.dialogMaxHeight!,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: t.headerColor,
                padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labels.title,
                        style: titleStyle.copyWith(
                          color: titleStyle.color ?? t.headerForegroundColor,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: labels.close,
                      color: t.headerForegroundColor,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: t.dialogPadding!,
                  child: PaeMathPanel(
                    initialLatex: initialLatex,
                    theme: theme,
                    labels: labels,
                    symbolGroups: symbolGroups,
                    templates: templates,
                    showSymbolsTab: showSymbolsTab,
                    showFormulaTab: showFormulaTab,
                    onSymbol: (c) => Navigator.pop(ctx, PaeMathSymbolInsertion(c)),
                    onFormula: (l) =>
                        Navigator.pop(ctx, PaeMathFormulaInsertion(l)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
