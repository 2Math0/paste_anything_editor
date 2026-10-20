import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../clipboard/pae_clipboard.dart';

/// A LaTeX formula with optional display (block) mode.
class PaeMathSnippet {
  const PaeMathSnippet(this.latex, {this.display = false});

  final String latex;
  final bool display;

  /// Value stored in a Quill `math-formula` embed.
  ///
  /// Inline formulas stay a plain [String] for backward compatibility.
  /// Display formulas use `{'latex': …, 'display': true}`.
  Object toEmbedValue() =>
      display ? <String, Object>{'latex': latex, 'display': true} : latex;

  /// Parses a Quill embed value produced by [toEmbedValue].
  static PaeMathSnippet fromEmbedValue(Object? value) {
    if (value is Map) {
      final latex = '${value['latex'] ?? ''}';
      return PaeMathSnippet(latex, display: value['display'] == true);
    }
    return PaeMathSnippet('$value');
  }

  @override
  bool operator ==(Object other) =>
      other is PaeMathSnippet &&
      other.latex == latex &&
      other.display == display;

  @override
  int get hashCode => Object.hash(latex, display);

  @override
  String toString() =>
      'PaeMathSnippet($latex, display: $display)';
}

/// Math formulas in HTML, plain text and the clipboard.
///
/// Saved form:
/// - inline: `<span class="math-tex" data-latex="LATEX">\(LATEX\)</span>`
/// - display: same with `data-display="true"` and `\[LATEX\]`
///
/// Recognised on paste: these spans, KaTeX output, MathJax v2 scripts, MathML
/// (`<annotation encoding="application/x-tex">` or `alttext`), CKEditor
/// `.math-tex`, and `$$..$$`, `\[..\]`, `\(..\)`, `$..$` in text.
abstract final class PaeMath {
  static const String cssClass = 'math-tex';
  static const String displayAttr = 'data-display';

  /// Placeholder left in text by [protect] and [extractFormulas];
  /// group 1 is the index into the formula list.
  static final Pattern tokenPattern = RegExp(r'\[\[pae-math-(\d+)\]\]');

  static const _attrEscape = HtmlEscape(HtmlEscapeMode.attribute);
  static const _textEscape = HtmlEscape(HtmlEscapeMode.element);

  /// `$$..$$`, `\[..\]`, `\(..\)`, or `$..$` (single-dollar filtered separately
  /// so prices like "$5 and $10" are left alone).
  static final RegExp _delimited = RegExp(
    r'\$\$([\s\S]+?)\$\$'
    r'|\\\[([\s\S]+?)\\\]'
    r'|\\\(([\s\S]+?)\\\)'
    r'|(?<![\\$\w])\$(?![\s$])([^$\n]+?)(?<!\s)\$(?![\w$])',
  );

  static final RegExp _wrapped = RegExp(
    r'^\s*(?:\$\$([\s\S]*)\$\$|\\\[([\s\S]*)\\\]|\\\(([\s\S]*)\\\)|\$([\s\S]*)\$)\s*$',
  );

  static final RegExp _displayWrapped = RegExp(r'^\s*(\$\$|\\\[)');

  static const Set<String> _rawTextTags = {
    'pre',
    'code',
    'script',
    'style',
    'textarea',
  };

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Removes one pair of surrounding delimiters (`$`, `$$`, `\(\)`, `\[\]`).
  static String normalizeLatex(String text) {
    final m = _wrapped.firstMatch(text);
    if (m == null) return text.trim();
    return (m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim();
  }

  /// Strips delimiters and records whether the source used display math
  /// (`$$…$$` / `\[…\]`). [display] overrides detection when non-null.
  static PaeMathSnippet parseSnippet(String text, {bool? display}) {
    final trimmed = text.trim();
    return PaeMathSnippet(
      normalizeLatex(trimmed),
      display: display ?? _displayWrapped.hasMatch(trimmed),
    );
  }

  static bool containsLatex(String text) {
    final formulas = <PaeMathSnippet>[];
    protect(text, formulas);
    return formulas.isNotEmpty;
  }

  /// Replaces delimited formulas in [text] with [tokenPattern] placeholders,
  /// appending each match to [formulas] (with display flag when from `$$`/`\[`).
  static String protect(String text, List<PaeMathSnippet> formulas) {
    return text.replaceAllMapped(_delimited, (m) {
      final fromDisplay = m.group(1) != null || m.group(2) != null;
      final fromInlineDollar = m.group(4) != null;
      final latex =
          (m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim();
      if (latex.isEmpty) return m.group(0)!;
      if (fromInlineDollar && !_isPlausibleInlineMath(latex)) {
        return m.group(0)!;
      }
      formulas.add(PaeMathSnippet(latex, display: fromDisplay));
      return '[[pae-math-${formulas.length - 1}]]';
    });
  }

  /// `$…$` content that looks like math, not currency or prose.
  static bool _isPlausibleInlineMath(String content) {
    final t = content.trim();
    if (t.isEmpty) return false;
    // "$5$", "$5.00$" — currency-like
    if (RegExp(r'^\d').hasMatch(t)) return false;
    // TeX markup
    if (RegExp(r'[\\^_{}]').hasMatch(t)) return true;
    // Expressions with operators
    if (RegExp(r'[+\-*/=<>]').hasMatch(t)) return true;
    // Single identifier: $x$, $alpha$, $x1$
    if (RegExp(r'^[A-Za-z\u0370-\u03FF][A-Za-z\u0370-\u03FF0-9]*$')
        .hasMatch(t)) {
      return true;
    }
    return false;
  }

  /// Replaces placeholders in [html] with formula spans.
  static String restorePlaceholders(
    String html,
    List<PaeMathSnippet> formulas,
  ) {
    if (formulas.isEmpty) return html;
    return html.replaceAllMapped(tokenPattern, (m) {
      final i = int.parse(m.group(1)!);
      if (i >= formulas.length) return m.group(0)!;
      final s = formulas[i];
      return formulaToHtml(s.latex, display: s.display);
    });
  }

  // ---------------------------------------------------------------------------
  // HTML
  // ---------------------------------------------------------------------------

  static String formulaToHtml(String latex, {bool display = false}) {
    final attr = _attrEscape.convert(latex);
    final text = _textEscape.convert(latex);
    final displayAttrValue = display ? ' $displayAttr="true"' : '';
    final body = display ? '\\[$text\\]' : '\\($text\\)';
    return '<span class="$cssClass"$displayAttrValue data-latex="$attr">'
        '$body</span>';
  }

  /// LaTeX of a formula element produced by [formulaToHtml] or a math library,
  /// or null if [el] is not a formula.
  static String? latexOf(dom.Element el) {
    final data = el.attributes['data-latex'];
    if (data != null && data.trim().isNotEmpty) return data.trim();
    if (el.classes.contains(cssClass)) {
      final tex = normalizeLatex(el.text);
      return tex.isEmpty ? null : tex;
    }
    return null;
  }

  /// Whether [el] represents display (block) math.
  static bool isDisplay(dom.Element el) {
    if (el.attributes[displayAttr] == 'true') return true;
    if (el.classes.contains('katex-display')) return true;
    final type = el.attributes['type'] ?? '';
    if (type.startsWith('math/tex') && type.contains('mode=display')) {
      return true;
    }
    // Inner text wrapped as \[…\]
    final text = el.text.trim();
    if (_displayWrapped.hasMatch(text) ||
        (text.startsWith('\\[') && text.endsWith('\\]'))) {
      return true;
    }
    return false;
  }

  /// Finds every formula under [root], replaces it with a [tokenPattern]
  /// placeholder and returns the snippets (index = token number).
  static List<PaeMathSnippet> extractFormulas(dom.Element root) {
    final formulas = <PaeMathSnippet>[];

    void replace(dom.Element el, String latex, {bool display = false}) {
      formulas.add(PaeMathSnippet(latex.trim(), display: display));
      el.replaceWith(dom.Text('[[pae-math-${formulas.length - 1}]]'));
    }

    String? texAnnotation(dom.Element el) {
      for (final a in el.querySelectorAll('annotation')) {
        if ((a.attributes['encoding'] ?? '').contains('tex')) {
          final t = a.text.trim();
          if (t.isNotEmpty) return t;
        }
      }
      return null;
    }

    for (final el
        in root.querySelectorAll('[data-latex], .$cssClass').toList()) {
      if (!_isAttached(el, root)) continue;
      final latex = latexOf(el);
      if (latex != null) replace(el, latex, display: isDisplay(el));
    }

    for (final el in root.querySelectorAll('.katex-display, .katex').toList()) {
      if (!_isAttached(el, root)) continue;
      final tex = texAnnotation(el);
      if (tex != null) {
        replace(
          el,
          tex,
          display: el.classes.contains('katex-display') || isDisplay(el),
        );
      }
    }

    for (final el in root.querySelectorAll('script').toList()) {
      if (!_isAttached(el, root)) continue;
      final type = el.attributes['type'] ?? '';
      if (type.startsWith('math/tex')) {
        replace(
          el,
          el.text,
          display: type.contains('mode=display'),
        );
      }
    }

    for (final el in root.querySelectorAll('math').toList()) {
      if (!_isAttached(el, root)) continue;
      final tex = texAnnotation(el) ?? el.attributes['alttext'];
      if (tex != null && tex.trim().isNotEmpty) {
        final display = el.attributes['display'] == 'block';
        replace(el, tex, display: display);
      } else {
        el.replaceWith(dom.Text(el.text));
      }
    }

    _protectTextNodes(root, formulas);
    return formulas;
  }

  /// Every formula snippet found in [html] (clipboard HTML, saved HTML).
  ///
  /// Uses the document element (not only `<body>`) so MathJax
  /// `<script type="math/tex">` tags that parsers place in `<head>` are found.
  static List<PaeMathSnippet> snippetsFromHtml(String html) {
    final root = html_parser.parse(html).documentElement;
    return root == null ? const [] : extractFormulas(root);
  }

  /// LaTeX strings of every formula found in [html].
  static List<String> formulasFromHtml(String html) =>
      snippetsFromHtml(html).map((s) => s.latex).toList(growable: false);

  static bool _isAttached(dom.Element el, dom.Element root) {
    dom.Node? node = el;
    while (node != null) {
      if (identical(node, root)) return true;
      node = node.parentNode;
    }
    return false;
  }

  static void _protectTextNodes(dom.Node node, List<PaeMathSnippet> formulas) {
    for (final child in node.nodes.toList()) {
      if (child is dom.Text) {
        final text = child.text;
        if (_delimited.hasMatch(text)) child.text = protect(text, formulas);
      } else if (child is dom.Element &&
          !_rawTextTags.contains(child.localName)) {
        _protectTextNodes(child, formulas);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  /// Copies [latex] as a formula span (`text/html`) plus delimited text, so
  /// it pastes as an equation in rich editors and as LaTeX elsewhere.
  /// Returns false if the browser rejected the write.
  static Future<bool> copyFormula(String latex, {bool display = false}) async {
    final plain = display ? '\\[$latex\\]' : '\\($latex\\)';
    if (await PaeClipboard.writeHtml(
      formulaToHtml(latex, display: display),
      plainText: plain,
    )) {
      return true;
    }
    return PaeClipboard.writeText(plain);
  }

  /// First formula on the clipboard (HTML first, then delimited or raw text),
  /// or null.
  static Future<String?> readFormula() async {
    final clip = await PaeClipboard.read();
    final html = clip.html;
    if (html != null) {
      final found = formulasFromHtml(html);
      if (found.isNotEmpty) return found.first;
    }
    final plain = clip.isAvailable ? clip.text : await PaeClipboard.readText();
    return plain == null ? null : formulaFromText(plain);
  }

  /// First delimited formula in [text], or the whole [text] without
  /// delimiters; null when blank.
  static String? formulaFromText(String text) {
    if (text.trim().isEmpty) return null;
    final formulas = <PaeMathSnippet>[];
    protect(text, formulas);
    return formulas.isNotEmpty ? formulas.first.latex : normalizeLatex(text);
  }
}
