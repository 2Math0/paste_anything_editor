import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../clipboard/pae_clipboard.dart';

/// Math formulas in HTML, plain text and the clipboard.
///
/// Saved form: `<span class="math-tex" data-latex="LATEX">\(LATEX\)</span>`,
/// readable as text and renderable by KaTeX / MathJax.
///
/// Recognised on paste: these spans, KaTeX output, MathJax v2 scripts, MathML
/// (`<annotation encoding="application/x-tex">` or `alttext`), CKEditor
/// `.math-tex`, and `$$..$$`, `\[..\]`, `\(..\)`, `$..$` in text.
abstract final class PaeMath {
  static const String cssClass = 'math-tex';

  /// Placeholder left in text by [protect] and [extractFormulas];
  /// group 1 is the index into the formula list.
  static final Pattern tokenPattern = RegExp(r'\[\[pae-math-(\d+)\]\]');

  static const _attrEscape = HtmlEscape(HtmlEscapeMode.attribute);
  static const _textEscape = HtmlEscape(HtmlEscapeMode.element);

  /// `$$..$$`, `\[..\]`, `\(..\)`, or `$..$` whose content looks like LaTeX
  /// (contains `\`, `^`, `_`, `{` or `}`) so prices like "$5 and $10" are
  /// left alone.
  static final Pattern _delimited = RegExp(
    r'\$\$([\s\S]+?)\$\$'
    r'|\\\[([\s\S]+?)\\\]'
    r'|\\\(([\s\S]+?)\\\)'
    r'|(?<![\\$\w])\$(?![\s$])([^$\n]*?[\\^_{}][^$\n]*?)(?<!\s)\$(?![\w$])',
  );

  static final Pattern _wrapped = RegExp(
    r'^\s*(?:\$\$([\s\S]*)\$\$|\\\[([\s\S]*)\\\]|\\\(([\s\S]*)\\\)|\$([\s\S]*)\$)\s*$',
  );

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
    final m = _wrapped.allMatches(text).firstOrNull;
    if (m == null) return text.trim();
    return (m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim();
  }

  static bool containsLatex(String text) => text.contains(_delimited);

  /// Replaces delimited formulas in [text] with [tokenPattern] placeholders,
  /// appending the LaTeX to [formulas].
  static String protect(String text, List<String> formulas) {
    return text.replaceAllMapped(_delimited, (m) {
      final latex =
          (m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim();
      if (latex.isEmpty) return m.group(0)!;
      formulas.add(latex);
      return '[[pae-math-${formulas.length - 1}]]';
    });
  }

  /// Replaces placeholders in [html] with formula spans.
  static String restorePlaceholders(String html, List<String> formulas) {
    if (formulas.isEmpty) return html;
    return html.replaceAllMapped(tokenPattern, (m) {
      final i = int.parse(m.group(1)!);
      return i < formulas.length ? formulaToHtml(formulas[i]) : m.group(0)!;
    });
  }

  // ---------------------------------------------------------------------------
  // HTML
  // ---------------------------------------------------------------------------

  static String formulaToHtml(String latex) {
    final attr = _attrEscape.convert(latex);
    final text = _textEscape.convert(latex);
    return '<span class="$cssClass" data-latex="$attr">\\($text\\)</span>';
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

  /// Finds every formula under [root], replaces it with a [tokenPattern]
  /// placeholder and returns the LaTeX list (index = token number).
  static List<String> extractFormulas(dom.Element root) {
    final formulas = <String>[];

    void replace(dom.Element el, String latex) {
      formulas.add(latex.trim());
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

    for (final el in root.querySelectorAll('[data-latex], .$cssClass').toList()) {
      if (!_isAttached(el, root)) continue;
      final latex = latexOf(el);
      if (latex != null) replace(el, latex);
    }

    for (final el in root.querySelectorAll('.katex-display, .katex').toList()) {
      if (!_isAttached(el, root)) continue;
      final tex = texAnnotation(el);
      if (tex != null) replace(el, tex);
    }

    for (final el in root.querySelectorAll('script').toList()) {
      if (!_isAttached(el, root)) continue;
      if ((el.attributes['type'] ?? '').startsWith('math/tex')) {
        replace(el, el.text);
      }
    }

    for (final el in root.querySelectorAll('math').toList()) {
      if (!_isAttached(el, root)) continue;
      final tex = texAnnotation(el) ?? el.attributes['alttext'];
      if (tex != null && tex.trim().isNotEmpty) {
        replace(el, tex);
      } else {
        el.replaceWith(dom.Text(el.text));
      }
    }

    _protectTextNodes(root, formulas);
    return formulas;
  }

  /// LaTeX of every formula found in [html] (clipboard HTML, saved HTML).
  static List<String> formulasFromHtml(String html) {
    final body = html_parser.parse(html).body;
    return body == null ? const [] : extractFormulas(body);
  }

  static bool _isAttached(dom.Element el, dom.Element root) {
    dom.Node? node = el;
    while (node != null) {
      if (identical(node, root)) return true;
      node = node.parentNode;
    }
    return false;
  }

  static void _protectTextNodes(dom.Node node, List<String> formulas) {
    for (final child in node.nodes.toList()) {
      if (child is dom.Text) {
        final text = child.text;
        if (text.contains(_delimited)) child.text = protect(text, formulas);
      } else if (child is dom.Element &&
          !_rawTextTags.contains(child.localName)) {
        _protectTextNodes(child, formulas);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  /// Copies [latex] as a formula span (`text/html`) plus `\(latex\)` text, so
  /// it pastes as an equation in rich editors and as LaTeX elsewhere.
  /// Returns false if the browser rejected the write.
  static Future<bool> copyFormula(String latex) async {
    final plain = '\\($latex\\)';
    if (await PaeClipboard.writeHtml(formulaToHtml(latex), plainText: plain)) {
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
    final formulas = <String>[];
    protect(text, formulas);
    return formulas.isNotEmpty ? formulas.first : normalizeLatex(text);
  }
}
