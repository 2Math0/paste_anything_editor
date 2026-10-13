import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart' as md;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../math/math_codec.dart';

/// All HTML / Markdown processing for `RichHtmlEditor`: clipboard markup
/// cleanup (meta, Office, Google Docs, code editors), HTML <-> Delta,
/// Markdown -> HTML, table and image sanitizing.
abstract final class RichHtmlCodec {
  /// Delta embed type holding a sanitized `<table>` HTML string.
  static const String tableEmbedType = 'html-table';

  /// Delta embed type holding an image URL (`http(s):` or `data:image/`).
  static const String imageEmbedType = 'image';

  /// The converter would emit `font` as a `ql-font-*` class; it is moved to
  /// this custom attribute and rendered as an inline `font-family` instead.
  static const String _inlineFontKey = 'inlineFont';

  static const Set<String> _nonContentTags = {
    'style',
    'script',
    'meta',
    'link',
    'title',
    'xml',
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

  static final Pattern _argbHex = RegExp(r'^#[0-9a-fA-F]{2}([0-9a-fA-F]{6})$');

  static final Pattern _tableToken = RegExp(r'\[\[pae-table-(\d+)\]\]');

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
    r'font-weight\s*:\s*(bold|bolder|[6-9]00)\b',
    caseSensitive: false,
  );
  static final Pattern _cssItalic = RegExp(
    r'font-style\s*:\s*(italic|oblique)\b',
    caseSensitive: false,
  );
  static final Pattern _cssUnderline = RegExp(
    r'text-decoration[a-z-]*\s*:[^;]*underline',
    caseSensitive: false,
  );
  static final Pattern _cssStrike = RegExp(
    r'text-decoration[a-z-]*\s*:[^;]*line-through',
    caseSensitive: false,
  );

  static final Pattern _whiteSpacePre =
      RegExp(r'white-space\s*:\s*pre\s*(;|$)', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------

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
  // Markdown
  // ---------------------------------------------------------------------------

  /// LaTeX is swapped for tokens first so Markdown doesn't turn `_` / `*`
  /// inside formulas into emphasis.
  static String markdownToHtml(String markdown) {
    final formulas = <String>[];
    final html = md.markdownToHtml(
      MathCodec.protect(markdown, formulas),
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    return MathCodec.restorePlaceholders(html, formulas);
  }

  // ---------------------------------------------------------------------------
  // HTML -> Delta
  // ---------------------------------------------------------------------------

  /// Converts HTML (including Word / Google Docs clipboard markup) to a Delta.
  /// Tables become [tableEmbedType] block embeds, formulas become
  /// [MathCodec.embedType] inline embeds. Images are kept only when
  /// [keepImages] is true and their source is displayable.
  static Delta htmlToDelta(String html, {bool keepImages = true}) {
    final document = html_parser.parse(html);
    final root = document.body ?? document.documentElement;
    if (root == null) return Delta()..insert('\n');

    final formulas = MathCodec.extractFormulas(root);
    _stripNonContent(root);
    for (final img in root.querySelectorAll('img').toList()) {
      if (!keepImages || !isRenderableImageSource(img.attributes['src'] ?? '')) {
        img.remove();
      }
    }
    for (final el in root.querySelectorAll('[style]')) {
      final style = el.attributes['style']!
          .split(';')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty && !d.toLowerCase().startsWith('mso-'))
          .map(_normalizeFontFamily)
          .join(';');
      el.attributes['style'] = style;
    }
    for (final b in root.querySelectorAll('b[id^="docs-internal-guid"]')) {
      for (final n in b.nodes.toList()) {
        b.parentNode!.insertBefore(n, b);
      }
      b.remove();
    }
    _cssFormattingToTags(root);

    final tables = <String>[];
    for (final table in root.querySelectorAll('table').toList()) {
      if (_hasTableAncestor(table)) continue;
      final token = '[[pae-table-${tables.length}]]';
      tables.add(
        MathCodec.restorePlaceholders(sanitizeTable(table), formulas),
      );
      table.replaceWith(dom.Element.tag('p')..text = token);
    }

    var delta = HtmlToDelta().convert(root.innerHtml);
    if (tables.isNotEmpty) delta = _expandTablePlaceholders(delta, tables);
    return MathCodec.expandPlaceholders(delta, formulas);
  }

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

  /// `font-family:"Calibri",sans-serif` -> `font-family:Calibri` so the value
  /// is a single name Quill and the HTML converter both accept.
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

  /// Google Docs expresses bold/italic/underline/strike as CSS on `<span>`,
  /// but [HtmlToDelta] only recognises the tags.
  static void _cssFormattingToTags(dom.Element root) {
    for (final el
        in root.querySelectorAll('span[style], a[style], font[style]')) {
      final style = el.attributes['style']!;
      final tags = [
        if (style.contains(_cssBold)) 'strong',
        if (style.contains(_cssItalic)) 'em',
        if (style.contains(_cssUnderline)) 'u',
        if (style.contains(_cssStrike)) 's',
      ];
      for (final tag in tags) {
        final wrapper = dom.Element.tag(tag);
        for (final n in el.nodes.toList()) {
          wrapper.append(n);
        }
        el.append(wrapper);
      }
    }
  }

  static bool _hasTableAncestor(dom.Element el) {
    var parent = el.parent;
    while (parent != null) {
      if (parent.localName == 'table') return true;
      parent = parent.parent;
    }
    return false;
  }

  static bool _endsWithNewline(Delta delta) {
    if (delta.isEmpty) return true;
    final last = delta.last.data;
    return last is String && last.endsWith('\n');
  }

  static Delta _expandTablePlaceholders(Delta source, List<String> tables) {
    final out = Delta();
    var skipNewline = false;
    for (final op in source.toList()) {
      final data = op.data;
      if (data is! String) {
        out.push(op);
        skipNewline = false;
        continue;
      }
      var text = data;
      if (skipNewline && text.startsWith('\n')) text = text.substring(1);
      skipNewline = false;

      var start = 0;
      for (final m in _tableToken.allMatches(text)) {
        var before = text.substring(start, m.start);
        if (skipNewline && before.startsWith('\n')) {
          before = before.substring(1);
        }
        if (before.isNotEmpty) out.insert(before, op.attributes);
        if (!_endsWithNewline(out)) out.insert('\n');
        out.insert({tableEmbedType: tables[int.parse(m.group(1)!)]});
        out.insert('\n');
        start = m.end;
        skipNewline = true;
      }
      var rest = text.substring(start);
      if (skipNewline && rest.startsWith('\n')) rest = rest.substring(1);
      if (rest.isNotEmpty) {
        out.insert(rest, op.attributes);
        skipNewline = false;
      }
    }
    if (!_endsWithNewline(out)) out.insert('\n');
    return out;
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

  // ---------------------------------------------------------------------------
  // Delta -> HTML
  // ---------------------------------------------------------------------------

  static String deltaToHtml(Delta delta) {
    final ops = _prepareOps(delta.toJson());
    final converter = QuillDeltaToHtmlConverter(
      ops,
      ConverterOptions(
        converterOptions: OpConverterOptions(
          customCssStyles: (op) {
            final font = op.attributes[_inlineFontKey];
            return font == null ? null : ["font-family:'$font'"];
          },
        ),
      ),
    );
    converter.renderCustomWith = (op, _) {
      if (op.insert.type == tableEmbedType) {
        return op.insert.value.toString();
      }
      if (op.insert.type == MathCodec.embedType) {
        return MathCodec.formulaToHtml(op.insert.value.toString());
      }
      return '';
    };
    return converter.convert();
  }

  /// Quill stores colors as `#AARRGGBB`, which the HTML converter drops.
  /// Table embeds are flagged as blocks and their trailing newline is dropped
  /// so no empty paragraph is emitted after the `<table>`.
  static List<Map<String, dynamic>> _prepareOps(List<dynamic> ops) {
    final result = <Map<String, dynamic>>[];
    var afterTable = false;
    for (final raw in ops) {
      final op = Map<String, dynamic>.from(raw as Map);
      final insert = op['insert'];

      if (insert is Map && insert.containsKey(tableEmbedType)) {
        op['attributes'] = {'renderAsBlock': true};
        result.add(op);
        afterTable = true;
        continue;
      }

      if (afterTable && insert is String && insert.startsWith('\n')) {
        afterTable = false;
        if (insert.length == 1) continue;
        op['insert'] = insert.substring(1);
      }
      afterTable = false;

      final attrs = op['attributes'];
      if (attrs is Map) {
        final fixed = Map<String, dynamic>.from(attrs);
        for (final key in const ['color', 'background']) {
          final v = fixed[key];
          if (v is String) {
            final m = _argbHex.allMatches(v).firstOrNull;
            if (m != null) fixed[key] = '#${m.group(1)}';
          }
        }
        final font = fixed.remove('font');
        if (font is String && font.isNotEmpty) fixed[_inlineFontKey] = font;
        op['attributes'] = fixed;
      }
      result.add(op);
    }
    return result;
  }
}
