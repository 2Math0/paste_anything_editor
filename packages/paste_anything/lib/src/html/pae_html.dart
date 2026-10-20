import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart' as md;

import '../math/pae_math.dart';

/// Turns clipboard markup (Word, Excel, Outlook, Google Docs, web pages,
/// code editors), Markdown and LaTeX text into clean, portable HTML.
abstract final class PaeHtml {
  static const _textEscape = HtmlEscape(HtmlEscapeMode.element);

  static const Set<String> _nonContentTags = {
    'style',
    'script',
    'meta',
    'link',
    'title',
    'xml',
    'iframe',
    'frame',
    'frameset',
    'object',
    'embed',
    'applet',
    'base',
    'noscript',
    'template',
  };

  static const Set<String> _urlAttributes = {
    'href',
    'src',
    'action',
    'formaction',
    'xlink:href',
  };

  static const Set<String> _allowedTableAttributes = {'colspan', 'rowspan'};

  static const Set<String> _allowedImageAttributes = {
    'src',
    'alt',
    'width',
    'height',
  };

  static const Set<String> _allowedTableStyles = {
    'color',
    'background-color',
    'text-align',
    'vertical-align',
    'font-weight',
    'font-style',
    'font-family',
    'text-decoration',
  };

  /// Word puts `file:///` paths and Outlook `cid:` references in `<img>`;
  /// browsers can't load those, so only these schemes are kept.
  static final Pattern _renderableImage =
      RegExp(r'^(https?:|data:image/)', caseSensitive: false);

  static final Pattern _simpleColorValue = RegExp(
    r'^(#[0-9a-f]{3,8}|rgba?\([^)]*\)|[a-z]+)$',
    caseSensitive: false,
  );

  static final Pattern _htmlSource = RegExp(
    r'<\s*(table|thead|tbody|tr|td|th|p|div|span|br|b|strong|i|em|u|s|h[1-6]|ul|ol|li|a|img|blockquote|pre|code|font)\b[^>]*>',
    caseSensitive: false,
  );

  static final List<Pattern> _markdownHints = [
    RegExp(r'^#{1,6}\s+\S', multiLine: true),
    RegExp(r'^\s*[-*+]\s+\S', multiLine: true),
    RegExp(r'^\s*\d+[.)]\s+\S', multiLine: true),
    RegExp(r'^\s*>\s?\S', multiLine: true),
    RegExp(r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$',
        multiLine: true),
    RegExp(r'^\s*```', multiLine: true),
    RegExp(r'\*\*[^*\n]+\*\*|__[^_\n]+__'),
    RegExp(r'\[[^\]\n]+\]\([^)\s]+\)'),
    RegExp(r'`[^`\n]+`'),
  ];

  static final Pattern _cssBold = RegExp(
    r'^font-weight\s*:\s*(bold|bolder|[6-9]00)\b',
    caseSensitive: false,
  );
  static final Pattern _cssItalic = RegExp(
    r'^font-style\s*:\s*(italic|oblique)\b',
    caseSensitive: false,
  );
  static final Pattern _cssUnderline = RegExp(
    r'^text-decoration[a-z-]*\s*:[^;]*underline',
    caseSensitive: false,
  );
  static final Pattern _cssStrike = RegExp(
    r'^text-decoration[a-z-]*\s*:[^;]*line-through',
    caseSensitive: false,
  );

  static final Pattern _unsafeUrl = RegExp(
    r'^\s*(javascript|vbscript|data):',
    caseSensitive: false,
  );

  static final Pattern _whiteSpacePre =
      RegExp(r'white-space\s*:\s*pre\s*(;|$)', caseSensitive: false);

  static final Pattern _tag =
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  static final Pattern _whitespace = RegExp(r'\s+');

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------

  /// Whether plain [text] is HTML source (e.g. copied from a code editor).
  static bool looksLikeHtml(String text) {
    final t = text.trimLeft();
    return t.startsWith('<') && t.contains(_htmlSource);
  }

  static bool looksLikeMarkdown(String text) =>
      _markdownHints.any(text.contains);

  /// Whether [src] is an image URL the browser can display.
  static bool isRenderableImageSource(String src) =>
      src.trim().startsWith(_renderableImage);

  /// Whether [html] has anything to insert besides markup: text, a table, a
  /// formula, or (when [countImages]) a displayable image. A browser's
  /// "Copy image" yields HTML that is just `<img>`.
  static bool hasVisibleContent(String html, {bool countImages = false}) {
    final body = html_parser.parse(html).body;
    if (body == null) return false;
    _stripNonContent(body);
    if (body.text.trim().isNotEmpty) return true;
    if (body.querySelector('table, math, [data-latex]') != null) return true;
    return countImages &&
        body
            .querySelectorAll('img')
            .any((i) => isRenderableImageSource(i.attributes['src'] ?? ''));
  }

  /// VS Code / JetBrains wrap the whole copy in one `<div>` or `<pre>` with
  /// `white-space: pre`. Google Docs also uses `white-space:pre`, but only on
  /// inner spans, so only the outer wrapper is checked.
  static bool isCodeEditorHtml(String html) {
    final body = html_parser.parse(html).body;
    if (body == null) return false;
    final roots = body.children.where((e) => e.localName != 'meta').toList();
    if (roots.length != 1) return false;
    final root = roots.single;
    if (root.localName == 'pre') return true;
    return root.localName == 'div' &&
        (root.attributes['style'] ?? '').contains(_whiteSpacePre);
  }

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  /// Cleans clipboard or saved HTML:
  ///
  /// - drops comments, `<script>`, `<style>`, `<meta>`, embeds, Office tags
  ///   (`o:p`, `v:shape`), `mso-*` styles, `on*` handlers and
  ///   `javascript:` URLs;
  /// - turns CSS bold / italic / underline / strike (Google Docs) into tags;
  /// - keeps one font family per declaration;
  /// - sanitizes tables to cells, spans and simple styles;
  /// - turns KaTeX, MathJax, MathML and `$..$` text into formula spans
  ///   ([PaeMath.formulaToHtml]);
  /// - keeps displayable images only when [keepImages] is true.
  ///
  /// The result is stable: normalizing it again returns the same HTML.
  static String normalize(String html, {bool keepImages = true}) {
    final document = html_parser.parse(html);
    final root = document.body ?? document.documentElement;
    if (root == null) return '';

    // Parsers often park <script> in <head>; move math scripts into [root]
    // so extractFormulas / restore keep them in the normalized output.
    final head = document.head;
    if (head != null && !identical(head, root)) {
      for (final el
          in head.querySelectorAll('script[type^="math/tex"]').toList()) {
        root.append(el);
      }
    }

    final formulas = PaeMath.extractFormulas(root);
    _stripNonContent(root);
    _stripUnsafeAttributes(root);
    for (final img in root.querySelectorAll('img').toList()) {
      if (!keepImages || !isRenderableImageSource(img.attributes['src'] ?? '')) {
        img.remove();
      }
    }
    for (final b in root.querySelectorAll('b[id^="docs-internal-guid"]')) {
      for (final n in b.nodes.toList()) {
        b.parentNode!.insertBefore(n, b);
      }
      b.remove();
    }
    _cleanStyles(root);

    for (final table in root.querySelectorAll('table').toList()) {
      if (_hasTableAncestor(table)) continue;
      final clean = html_parser.parseFragment(sanitizeTable(table)).nodes;
      if (clean.isEmpty) {
        table.remove();
      } else {
        table.replaceWith(clean.first);
      }
    }

    return PaeMath.restorePlaceholders(root.innerHtml.trim(), formulas);
  }

  /// GitHub-flavored Markdown to HTML. LaTeX is protected first so Markdown
  /// doesn't turn `_` / `*` inside formulas into emphasis.
  static String fromMarkdown(String markdown) {
    final formulas = <PaeMathSnippet>[];
    final html = md.markdownToHtml(
      PaeMath.protect(markdown, formulas),
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    return PaeMath.restorePlaceholders(html, formulas);
  }

  /// Plain text to escaped HTML paragraphs, with delimited LaTeX turned into
  /// formula spans.
  static String fromPlainText(String text) {
    final formulas = <PaeMathSnippet>[];
    final protected = PaeMath.protect(text, formulas);
    return protected.split('\n').map((line) {
      final escaped = _textEscape.convert(line);
      return escaped.trim().isEmpty
          ? '<p><br></p>'
          : '<p>${PaeMath.restorePlaceholders(escaped, formulas)}</p>';
    }).join();
  }

  /// Text content of [html] with whitespace collapsed, for the `text/plain`
  /// flavor of a copy.
  static String toPlainText(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(_tag, ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // Tables
  // ---------------------------------------------------------------------------

  /// Returns a clean, self-contained `<table>` HTML string for [table].
  static String sanitizeTable(dom.Element table) {
    final clone = table.clone(true);
    _stripNonContent(clone);

    for (final img in clone.querySelectorAll('img').toList()) {
      if (!isRenderableImageSource(img.attributes['src'] ?? '')) img.remove();
    }

    void clean(dom.Element el) {
      final style = el.attributes['style'];
      final allowed = el.localName == 'img'
          ? _allowedImageAttributes
          : _allowedTableAttributes;
      el.attributes.removeWhere((key, _) => !allowed.contains(key.toString()));
      if (style != null) {
        final filtered = _filterTableStyle(style);
        if (filtered.isNotEmpty) el.attributes['style'] = filtered;
      }
      for (final child in el.children) {
        clean(child);
      }
    }

    clean(clone);

    for (final cell in clone.querySelectorAll('td, th')) {
      final blocks = cell.children.where((c) => c.localName == 'p').toList();
      if (blocks.length == 1 && cell.children.length == 1) {
        final p = blocks.first;
        for (final n in p.nodes.toList()) {
          cell.insertBefore(n, p);
        }
        p.remove();
      }
    }

    clone.attributes['border'] = '1';
    clone.attributes['cellpadding'] = '6';
    clone.attributes['style'] = 'border-collapse:collapse';
    return clone.outerHtml;
  }

  /// Parses [source] and returns the sanitized first `<table>`, or null.
  static String? sanitizeTableSource(String source) {
    final table = html_parser.parse(source).querySelector('table');
    return table == null ? null : sanitizeTable(table);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Removes comments, `<meta>`/`<style>`/... and Office namespaced tags
  /// (`o:p`, `v:shape`, ...) from [root] in place.
  static void _stripNonContent(dom.Node root) {
    for (final node in root.nodes.toList()) {
      if (node is dom.Comment) {
        node.remove();
      } else if (node is dom.Element) {
        final name = node.localName ?? '';
        if (name.contains(':') || _nonContentTags.contains(name)) {
          node.remove();
        } else {
          _stripNonContent(node);
        }
      }
    }
  }

  /// Removes `on*` event handlers and `javascript:` / `vbscript:` / `data:`
  /// URLs (except displayable `data:image/` images).
  static void _stripUnsafeAttributes(dom.Element root) {
    for (final el in root.querySelectorAll('*')) {
      el.attributes.removeWhere((key, value) {
        final name = key.toString().toLowerCase();
        if (name.startsWith('on')) return true;
        if (!_urlAttributes.contains(name) || !value.contains(_unsafeUrl)) {
          return false;
        }
        return !(el.localName == 'img' &&
            name == 'src' &&
            isRenderableImageSource(value));
      });
    }
  }

  /// Drops `mso-*` declarations, keeps one font family, and moves CSS
  /// bold / italic / underline / strike on inline elements into tags, since
  /// most editors only recognise the tags.
  static void _cleanStyles(dom.Element root) {
    for (final el in root.querySelectorAll('[style]')) {
      final inline = const {'span', 'a', 'font'}.contains(el.localName);
      final tags = <String>{};
      final kept = <String>[];
      for (final raw in el.attributes['style']!.split(';')) {
        final d = raw.trim();
        if (d.isEmpty || d.toLowerCase().startsWith('mso-')) continue;
        if (inline) {
          final before = tags.length;
          if (d.contains(_cssBold)) tags.add('strong');
          if (d.contains(_cssItalic)) tags.add('em');
          if (d.contains(_cssUnderline)) tags.add('u');
          if (d.contains(_cssStrike)) tags.add('s');
          if (tags.length != before) continue;
        }
        final normalized = _normalizeFontFamily(d);
        if (normalized.isNotEmpty) kept.add(normalized);
      }
      if (kept.isEmpty) {
        el.attributes.remove('style');
      } else {
        el.attributes['style'] = kept.join(';');
      }
      for (final tag in tags) {
        final wrapper = dom.Element.tag(tag);
        for (final n in el.nodes.toList()) {
          wrapper.append(n);
        }
        el.append(wrapper);
      }
    }
  }

  /// `font-family:"Calibri",sans-serif` -> `font-family:Calibri` so the value
  /// is a single name editors accept.
  static String _normalizeFontFamily(String declaration) {
    final idx = declaration.indexOf(':');
    if (idx <= 0) return declaration;
    final prop = declaration.substring(0, idx).trim().toLowerCase();
    if (prop != 'font-family') return declaration;
    final first = declaration
        .substring(idx + 1)
        .split(',')
        .first
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return first.isEmpty ? '' : 'font-family:$first';
  }

  static bool _hasTableAncestor(dom.Element el) {
    var parent = el.parent;
    while (parent != null) {
      if (parent.localName == 'table') return true;
      parent = parent.parent;
    }
    return false;
  }

  static String _filterTableStyle(String style) {
    final kept = <String>[];
    for (final declaration in style.split(';')) {
      final idx = declaration.indexOf(':');
      if (idx <= 0) continue;
      var prop = declaration.substring(0, idx).trim().toLowerCase();
      final value = declaration.substring(idx + 1).trim();
      if (value.isEmpty) continue;
      if (prop == 'background' && value.contains(_simpleColorValue)) {
        prop = 'background-color';
      }
      if (_allowedTableStyles.contains(prop)) kept.add('$prop:$value');
    }
    return kept.join(';');
  }
}
