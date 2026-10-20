import 'package:flutter/material.dart';

import 'pae_math_theme.dart';
import 'pae_math_symbols.dart';

/// How the editor's math toolbar button opens math input.
enum PaeMathInputMode {
  /// Docked [PaeMathKeyboard] at the bottom of the screen; the editor keeps
  /// focus, so the cursor can move while symbols stay available.
  keyboard,

  /// Modal [PaeMathDialog].
  dialog,
}

/// Docked math keyboard: symbol categories plus formula templates.
///
/// It never takes focus and counts as part of the text field's tap region,
/// so an editor keeps its cursor and selection while the user taps keys.
class PaeMathKeyboard extends StatefulWidget {
  const PaeMathKeyboard({
    super.key,
    required this.onSymbol,
    this.onFormula,
    this.onOpenLatexEditor,
    this.onClose,
    this.theme,
    this.labels = const PaeMathLabels(),
    this.symbolGroups,
    this.templates,
  });

  /// Called with the Unicode character of a tapped symbol.
  final ValueChanged<String> onSymbol;

  /// Called with a template's LaTeX. The formulas category is hidden when
  /// null.
  final ValueChanged<String>? onFormula;

  /// Shows a "LaTeX editor" button when set.
  final VoidCallback? onOpenLatexEditor;

  /// Shows a hide button when set.
  final VoidCallback? onClose;

  final PaeMathTheme? theme;
  final PaeMathLabels labels;

  /// Defaults to [kPaeMathSymbolGroups].
  final List<PaeMathSymbolGroup>? symbolGroups;

  /// Defaults to [kPaeMathTemplates].
  final List<PaeMathTemplate>? templates;

  @override
  State<PaeMathKeyboard> createState() => _PaeMathKeyboardState();
}

class _PaeMathKeyboardState extends State<PaeMathKeyboard> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final t = PaeMathTheme.resolve(context, widget.theme);
    final labels = widget.labels;
    final groups = widget.symbolGroups ?? kPaeMathSymbolGroups;
    final templates = widget.onFormula == null
        ? const <PaeMathTemplate>[]
        : widget.templates ?? kPaeMathTemplates;
    final categories = [
      for (final g in groups) g.title,
      if (templates.isNotEmpty) labels.formulasCategory,
    ];
    if (categories.isEmpty) return const SizedBox.shrink();
    final selected = _category.clamp(0, categories.length - 1);
    final showFormulas = selected >= groups.length;
    final headerFg = t.headerForegroundColor!;
    final titleStyle = t.titleTextStyle!;

    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: Theme(
          data: Theme.of(context).copyWith(colorScheme: t.colorScheme),
          child: Material(
            color: t.backgroundColor,
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(t.keyboardBorderRadius!),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: t.keyboardHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: t.headerColor,
                      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                      child: Row(
                        children: [
                          Icon(Icons.functions, color: headerFg, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            labels.keyboardTitle,
                            style: titleStyle.copyWith(
                              fontSize: 15,
                              color: titleStyle.color ?? headerFg,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (_, i) => _CategoryChip(
                                  label: categories[i],
                                  selected: i == selected,
                                  theme: t,
                                  onTap: () => setState(() => _category = i),
                                ),
                              ),
                            ),
                          ),
                          if (widget.onOpenLatexEditor != null)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: headerFg,
                              ),
                              onPressed: widget.onOpenLatexEditor,
                              icon: const Icon(Icons.edit_note, size: 20),
                              label: Text(labels.openLatexEditor),
                            ),
                          if (widget.onClose != null)
                            IconButton(
                              tooltip: labels.hideKeyboard,
                              color: headerFg,
                              icon: const Icon(Icons.keyboard_hide_outlined),
                              onPressed: widget.onClose,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: t.keyboardMaxWidth!),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: showFormulas
                                ? _templateKeys(t, templates)
                                : _symbolKeys(t, groups[selected]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _symbolKeys(PaeMathTheme t, PaeMathSymbolGroup group) {
    final size = t.symbolTileSize!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in group.symbols)
          _Key(
            theme: t,
            width: size,
            height: size,
            tooltip: s.latex == null ? s.name : '${s.name}  ${s.latex}',
            onTap: () => widget.onSymbol(s.char),
            child: Text(
              s.char,
              style: TextStyle(fontSize: t.symbolFontSize, color: t.symbolColor),
            ),
          ),
      ],
    );
  }

  Widget _templateKeys(PaeMathTheme t, List<PaeMathTemplate> templates) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tpl in templates)
          _Key(
            theme: t,
            height: t.symbolTileSize! * 1.4,
            minWidth: t.symbolTileSize! * 1.6,
            tooltip: '${tpl.tooltip}\n${tpl.latex}',
            onTap: () => widget.onFormula!(tpl.latex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                tpl.label,
                style: TextStyle(
                  fontSize: t.compactSymbolFontSize,
                  color: t.symbolColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final PaeMathTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: selected ? t.chipSelectedColor : t.chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.chipBorderRadius!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? t.chipSelectedLabelColor : t.chipLabelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.theme,
    required this.height,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.width,
    this.minWidth,
  });

  final PaeMathTheme theme;
  final double height;
  final double? width;
  final double? minWidth;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? minWidth ?? 0,
          maxWidth: width ?? double.infinity,
          minHeight: height,
          maxHeight: height,
        ),
        child: Material(
          color: t.symbolTileColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.tileBorderRadius!),
            side: BorderSide(color: t.symbolTileBorderColor!),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(widthFactor: width == null ? 1 : null, child: child),
          ),
        ),
      ),
    );
  }
}
