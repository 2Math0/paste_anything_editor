import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../clipboard/rich_clipboard.dart';

/// Math formulas in HTML, plain text, Quill Delta and the clipboard.
///
/// Saved form: `<span class="math-tex" data-latex="LATEX">\(LATEX\)</span>`,
/// readable as text and renderable by KaTeX / MathJax.
///
/// Recognised on paste: our spans, KaTeX output, MathJax v2 scripts, MathML
/// (`<annotation encoding="application/x-tex">` or `alttext`), CKEditor
/// `.math-tex`, and `$$..$$`, `\[..\]`, `\(..\)`, `$..$` in text.
abstract final class MathCodec {
  /// Inline Delta embed type holding a LaTeX string.
  static const String embedType = 'math-formula';

  static const String cssClass = 'math-tex';

  static const _attrEscape = HtmlEscape(HtmlEscapeMode.attribute);
  static const _textEscape = HtmlEscape(HtmlEscapeMode.element);

  static final Pattern _token = RegExp(r'\[\[pae-math-(\d+)\]\]');

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

  /// Replaces delimited formulas in [text] with placeholder tokens, appending
  /// the LaTeX to [formulas].
  static String protect(String text, List<String> formulas) {
    return text.replaceAllMapped(_delimited, (m) {
      final latex =
          (m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim();
      if (latex.isEmpty) return m.group(0)!;
      formulas.add(latex);
      return '[[pae-math-${formulas.length - 1}]]';
    });
  }

  /// Replaces placeholder tokens in [html] with formula spans.
  static String restorePlaceholders(String html, List<String> formulas) {
    if (formulas.isEmpty) return html;
    return html.replaceAllMapped(_token, (m) {
      final i = int.parse(m.group(1)!);
      return i < formulas.length ? formulaToHtml(formulas[i]) : m.group(0)!;
    });
  }

  /// Plain text with LaTeX delimiters -> HTML paragraphs with formula spans.
  static String plainTextToHtml(String text) {
    final formulas = <String>[];
    final protected = protect(text, formulas);
    return protected.split('\n').map((line) {
      final escaped = _textEscape.convert(line);
      return escaped.trim().isEmpty
          ? '<p><br></p>'
          : '<p>${restorePlaceholders(escaped, formulas)}</p>';
    }).join();
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

  /// Finds every formula under [root], replaces it with a placeholder token
  /// and returns the LaTeX list (index = token number).
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
  // Delta
  // ---------------------------------------------------------------------------

  /// Turns placeholder tokens in text ops into inline [embedType] embeds,
  /// keeping the surrounding text attributes.
  static Delta expandPlaceholders(Delta source, List<String> formulas) {
    if (formulas.isEmpty) return source;
    final out = Delta();
    for (final op in source.toList()) {
      final data = op.data;
      if (data is! String) {
        out.push(op);
        continue;
      }
      var start = 0;
      for (final m in _token.allMatches(data)) {
        final i = int.parse(m.group(1)!);
        if (i >= formulas.length) continue;
        final before = data.substring(start, m.start);
        if (before.isNotEmpty) out.insert(before, op.attributes);
        out.insert({embedType: formulas[i]}, op.attributes);
        start = m.end;
      }
      final rest = data.substring(start);
      if (rest.isNotEmpty) out.insert(rest, op.attributes);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  static Future<void> copySymbol(String char) =>
      Clipboard.setData(ClipboardData(text: char));

  /// Copies [latex] as a formula span (`text/html`) plus `\(latex\)` text, so
  /// it pastes as an equation here and as LaTeX in plain-text apps.
  static Future<void> copyFormula(String latex) async {
    final plain = '\\($latex\\)';
    if (await writeClipboardHtml(formulaToHtml(latex), plainText: plain)) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: plain));
  }

  static Future<void> copyLatex(String latex) =>
      Clipboard.setData(ClipboardData(text: latex));

  /// First formula on the clipboard (HTML first, then delimited or raw text),
  /// or null.
  static Future<String?> readFormulaFromClipboard() async {
    final html = await readClipboardHtml();
    if (html != null) {
      final found = formulasFromHtml(html);
      if (found.isNotEmpty) return found.first;
    }
    final plain = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (plain == null || plain.trim().isEmpty) return null;
    final formulas = <String>[];
    protect(plain, formulas);
    return formulas.isNotEmpty ? formulas.first : normalizeLatex(plain);
  }
}
