import 'package:flutter_test/flutter_test.dart';
import 'package:paste_anything_editor/paste_anything_editor.dart';

void main() {
  group('PaeQuillCodec math', () {
    test('htmlToDelta turns formula span into math embed', () {
      final html = '<p>Hi ${PaeMath.formulaToHtml(r'x^2')} there</p>';
      final delta = PaeQuillCodec.htmlToDelta(html);
      final ops = delta.toJson();

      final mathOp = ops.cast<Map>().firstWhere(
        (op) {
          final insert = op['insert'];
          return insert is Map && insert.containsKey(PaeQuillCodec.mathEmbedType);
        },
      );
      final embed = mathOp['insert'][PaeQuillCodec.mathEmbedType];
      expect(PaeMathSnippet.fromEmbedValue(embed).latex, r'x^2');
      expect(PaeMathSnippet.fromEmbedValue(embed).display, isFalse);
    });

    test('htmlToDelta preserves display math', () {
      final html = PaeMath.formulaToHtml(r'\sum_{i=1}^n i', display: true);
      final delta = PaeQuillCodec.htmlToDelta('<p>$html</p>');
      final ops = delta.toJson();
      final mathOp = ops.cast<Map>().firstWhere(
        (op) {
          final insert = op['insert'];
          return insert is Map && insert.containsKey(PaeQuillCodec.mathEmbedType);
        },
      );
      final snippet = PaeMathSnippet.fromEmbedValue(
        mathOp['insert'][PaeQuillCodec.mathEmbedType],
      );
      expect(snippet.latex, r'\sum_{i=1}^n i');
      expect(snippet.display, isTrue);
    });

    test('deltaToHtml roundtrip keeps latex and display', () {
      final original = PaeMath.formulaToHtml(r'a+b', display: true);
      final delta = PaeQuillCodec.htmlToDelta('<p>$original</p>');
      final html = PaeQuillCodec.deltaToHtml(delta);
      expect(html, contains('data-latex="a+b"'));
      expect(html, contains('data-display="true"'));

      final again = PaeMath.snippetsFromHtml(html);
      expect(again, hasLength(1));
      expect(again.first.display, isTrue);
      expect(again.first.latex, 'a+b');
    });

    test('plain delimited text becomes embeds', () {
      final delta = PaeQuillCodec.htmlToDelta(
        PaeHtml.fromPlainText(r'See $x$ and $$y$$'),
      );
      final embeds = delta
          .toJson()
          .cast<Map>()
          .where((op) {
            final insert = op['insert'];
            return insert is Map &&
                insert.containsKey(PaeQuillCodec.mathEmbedType);
          })
          .map(
            (op) => PaeMathSnippet.fromEmbedValue(
              op['insert'][PaeQuillCodec.mathEmbedType],
            ),
          )
          .toList();

      expect(embeds, hasLength(2));
      expect(embeds[0], const PaeMathSnippet('x'));
      expect(embeds[1], const PaeMathSnippet('y', display: true));
    });
  });

  group('templates', () {
    test('matrix templates use matching delimiters', () {
      final byTooltip = {
        for (final t in kPaeMathTemplates) t.tooltip: t,
      };
      expect(byTooltip['Matrix (parentheses)']!.latex, contains('pmatrix'));
      expect(byTooltip['Matrix (brackets)']!.latex, contains('bmatrix'));
      expect(byTooltip['Determinant']!.latex, contains('vmatrix'));
      expect(byTooltip.containsKey('Align'), isFalse);
    });
  });
}
