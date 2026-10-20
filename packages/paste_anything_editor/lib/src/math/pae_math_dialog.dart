import 'dart:async';

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
  /// Only created when both tabs are shown. A `late final` initializer would
  /// lazily construct a [TabController] inside [dispose] for formula-only
  /// dialogs and look up [TickerMode] on a deactivated element.
  TabController? _tabs;
  late final TextEditingController _latex =
      TextEditingController(text: widget.initialLatex ?? '');
  final FocusNode _latexFocus = FocusNode();

  /// Cached in [didChangeDependencies] so async toasts never walk a dead tree.
  ScaffoldMessengerState? _messenger;
  Timer? _previewTimer;
  late String _previewLatex = PaeMath.normalizeLatex(_latex.text);

  PaeMathLabels get _labels => widget.labels;
  List<PaeMathSymbolGroup> get _groups => widget.symbolGroups ?? kPaeMathSymbolGroups;

  @override
  void initState() {
    super.initState();
    if (_bothTabs) {
      _tabs = TabController(
        length: 2,
        vsync: this,
        initialIndex: widget.initialLatex != null ? 1 : 0,
      );
    }
    _latex.addListener(_schedulePreview);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _latex.removeListener(_schedulePreview);
    // Drop focus before disposing the node so FocusScope is not looked up on
    // a deactivated element (common when the dialog pops after a tap).
    _latexFocus.canRequestFocus = false;
    if (_latexFocus.hasPrimaryFocus || _latexFocus.hasFocus) {
      _latexFocus.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
    _tabs?.dispose();
    _latex.dispose();
    _latexFocus.dispose();
    super.dispose();
  }

  String get _formula => PaeMath.normalizeLatex(_latex.text);

  void _schedulePreview() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final next = PaeMath.normalizeLatex(_latex.text);
      if (next == _previewLatex) return;
      setState(() => _previewLatex = next);
    });
  }

  void _toast(String message) {
    _messenger?.showSnackBar(SnackBar(content: Text(message)));
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
    if (!mounted) return;
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
    if (!mounted) return;
    if (latex == null || latex.isEmpty) {
      _toast(_labels.noFormulaOnClipboard);
      return;
    }
    _insertIntoFormula(latex);
  }

  Future<void> _copyFormula() async {
    if (_formula.isEmpty) return;
    await PaeMath.copyFormula(_formula);
    if (!mounted) return;
    _toast(_labels.formulaCopied);
  }

  Future<void> _copyLatex() async {
    if (_formula.isEmpty) return;
    await PaeClipboard.writeText(_formula);
    if (!mounted) return;
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
    final pillRadius = BorderRadius.circular(t.chipBorderRadius! + 4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.inputFillColor,
            borderRadius: pillRadius,
          ),
          child: TabBar(
            controller: _tabs!,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: t.chipSelectedColor,
              borderRadius: pillRadius,
            ),
            labelColor: t.chipSelectedLabelColor,
            unselectedLabelColor: t.tabUnselectedColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(
                height: 40,
                iconMargin: const EdgeInsets.only(bottom: 2),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                text: _labels.symbolsTab,
              ),
              Tab(
                height: 40,
                iconMargin: const EdgeInsets.only(bottom: 2),
                icon: const Icon(Icons.functions_rounded, size: 18),
                text: _labels.formulaTab,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          // Build only the visible tab — TabBarView would mount both and
          // parse every formula template up front.
          child: ListenableBuilder(
            listenable: _tabs!,
            builder: (context, _) => _tabs!.index == 0
                ? _buildSymbolsTab(context, t)
                : _buildFormulaTab(context, t),
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
    final sectionStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: t.tabUnselectedColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_labels.templatesLabel, style: sectionStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tpl in widget.templates ?? kPaeMathTemplates)
              Tooltip(
                message: '${tpl.tooltip}\n${tpl.latex}',
                child: Material(
                  color: t.templateChipColor,
                  shape: chipShape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _insertIntoFormula(tpl.latex),
                    customBorder: chipShape,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        tpl.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.templateChipLabelColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
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
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            border: OutlineInputBorder(borderRadius: fieldRadius),
            enabledBorder: OutlineInputBorder(
              borderRadius: fieldRadius,
              borderSide: BorderSide(color: t.previewBorderColor!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: fieldRadius,
              borderSide: BorderSide(color: t.actionColor!, width: 1.5),
            ),
            suffixIcon: IconButton(
              tooltip: _labels.pasteFormula,
              icon: const Icon(Icons.content_paste_rounded),
              onPressed: _pasteFormula,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_labels.preview, style: sectionStyle),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(minHeight: t.previewMinHeight!),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: t.previewBorderColor!),
            borderRadius: fieldRadius,
            color: t.previewBackgroundColor,
          ),
          alignment: Alignment.centerLeft,
          child: _previewLatex.isEmpty
              ? Text(
                  _labels.latexHint,
                  style: TextStyle(
                    color: t.tabUnselectedColor,
                    fontSize: 13,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: PaeMathView(
                    _previewLatex,
                    display: true,
                    textStyle: TextStyle(
                      fontSize: t.previewFontSize,
                      color: t.previewFormulaColor,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _SymbolPalette(
            groups: _groups,
            theme: t,
            compact: true,
            onTap: (s) => _insertIntoFormula(s.latexOrChar),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _latex,
          builder: (context, value, _) {
            final hasFormula = PaeMath.normalizeLatex(value.text).isNotEmpty;
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: t.previewBorderColor!),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: hasFormula ? _copyLatex : null,
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: Text(_labels.copyLatex),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasFormula ? _copyFormula : null,
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      label: Text(_labels.copyFormula),
                    ),
                    if (widget.onFormula != null)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: t.actionColor,
                          foregroundColor: t.actionForegroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              t.chipBorderRadius!,
                            ),
                          ),
                        ),
                        onPressed: hasFormula
                            ? () => widget.onFormula!(_formula)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(_labels.insert),
                      ),
                  ],
                ),
              ),
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
    final shape = t.resolveDialogShape();
    return showDialog<PaeMathInsertion>(
      context: context,
      barrierColor: t.barrierColor,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (ctx) => Dialog(
        backgroundColor: t.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: t.dialogElevation,
        shadowColor: t.dialogShadowColor,
        insetPadding: t.dialogInsetPadding,
        clipBehavior: t.dialogClipBehavior ?? Clip.antiAlias,
        shape: shape,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: t.dialogMaxWidth!,
            maxHeight: t.dialogMaxHeight!,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.headerColor,
                  border: Border(
                    bottom: BorderSide(
                      color: t.previewBorderColor!.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Padding(
                  padding: t.headerPadding!,
                  child: Row(
                    children: [
                      if (t.showHeaderIcon ?? true) ...[
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.actionColor!.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              t.tileBorderRadius!,
                            ),
                          ),
                          child: Icon(
                            Icons.functions_rounded,
                            size: 20,
                            color: t.actionColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          labels.title,
                          style: titleStyle.copyWith(
                            color: titleStyle.color ?? t.headerForegroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: labels.close,
                        color: t.headerForegroundColor,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _popAfterFrame(ctx),
                      ),
                    ],
                  ),
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
                    onSymbol: (c) => _popAfterFrame(
                      ctx,
                      PaeMathSymbolInsertion(c),
                    ),
                    onFormula: (l) => _popAfterFrame(
                      ctx,
                      PaeMathFormulaInsertion(l),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pop on the next frame so the tapping widget can finish dispose without
  /// walking a deactivated ancestor tree.
  static void _popAfterFrame(BuildContext ctx, [PaeMathInsertion? result]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(result);
    });
  }
}
