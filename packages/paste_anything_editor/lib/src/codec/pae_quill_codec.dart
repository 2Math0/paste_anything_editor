import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:paste_anything/paste_anything.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// HTML <-> Quill Delta for [PaeEditor]. Clipboard cleanup itself lives in
/// [PaeHtml.normalize]; this adds the Quill-specific parts: tables as block
/// embeds, formulas as inline embeds, colors and fonts Quill can store.
abstract final class PaeQuillCodec {
  /// Block embed holding a sanitized `<table>` HTML string.
  static const String tableEmbedType = 'html-table';

  /// Block embed holding an image URL (`http(s):` or `data:image/`).
  static const String imageEmbedType = 'image';

  /// Inline embed holding a LaTeX string.
  static const String mathEmbedType = 'math-formula';

  /// The converter would emit `font` as a `ql-font-*` class; it is moved to
  /// this custom attribute and rendered as an inline `font-family` instead.
  static const String _inlineFontKey = 'inlineFont';

  static final Pattern _argbHex = RegExp(r'^#[0-9a-fA-F]{2}([0-9a-fA-F]{6})$');

  static final Pattern _tableToken = RegExp(r'\[\[pae-table-(\d+)\]\]');

  // ---------------------------------------------------------------------------
  // HTML -> Delta
  // ---------------------------------------------------------------------------

  /// Converts HTML (including Word / Google Docs clipboard markup) to a Delta.
  /// Tables become [tableEmbedType] block embeds and formulas
  /// [mathEmbedType] inline embeds. Images are kept only when [keepImages]
  /// is true and their source is displayable.
  static Delta htmlToDelta(String html, {bool keepImages = true}) {
    final clean = PaeHtml.normalize(html, keepImages: keepImages);
    final root = html_parser.parse(clean).body;
    if (root == null) return Delta()..insert('\n');

    final formulas = PaeMath.extractFormulas(root);
    final tables = <String>[];
    for (final table in root.querySelectorAll('table').toList()) {
      if (_hasTableAncestor(table)) continue;
      final token = '[[pae-table-${tables.length}]]';
      tables.add(PaeMath.restorePlaceholders(table.outerHtml, formulas));
      table.replaceWith(dom.Element.tag('p')..text = token);
    }

    var delta = HtmlToDelta().convert(root.innerHtml);
    if (tables.isNotEmpty) delta = _expandTablePlaceholders(delta, tables);
    return _expandFormulaPlaceholders(delta, formulas);
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

  /// Turns [PaeMath.tokenPattern] placeholders in text ops into inline
  /// [mathEmbedType] embeds, keeping the surrounding text attributes.
  static Delta _expandFormulaPlaceholders(Delta source, List<String> formulas) {
    if (formulas.isEmpty) return source;
    final out = Delta();
    for (final op in source.toList()) {
      final data = op.data;
      if (data is! String) {
        out.push(op);
        continue;
      }
      var start = 0;
      for (final m in PaeMath.tokenPattern.allMatches(data)) {
        final i = int.parse(m.group(1)!);
        if (i >= formulas.length) continue;
        final before = data.substring(start, m.start);
        if (before.isNotEmpty) out.insert(before, op.attributes);
        out.insert({mathEmbedType: formulas[i]}, op.attributes);
        start = m.end;
      }
      final rest = data.substring(start);
      if (rest.isNotEmpty) out.insert(rest, op.attributes);
    }
    return out;
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
      if (op.insert.type == mathEmbedType) {
        return PaeMath.formulaToHtml(op.insert.value.toString());
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
