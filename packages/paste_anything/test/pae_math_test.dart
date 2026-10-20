import 'package:paste_anything/paste_anything.dart';
import 'package:test/test.dart';

void main() {
  group('PaeMath detection', () {
    test(r'detects $$, \[, \( and simple $x$', () {
      expect(PaeMath.containsLatex(r'$$a$$'), isTrue);
      expect(PaeMath.containsLatex(r'\[a\]'), isTrue);
      expect(PaeMath.containsLatex(r'\(a\)'), isTrue);
      expect(PaeMath.containsLatex(r'$x$'), isTrue);
      expect(PaeMath.containsLatex(r'$x^2$'), isTrue);
      expect(PaeMath.containsLatex(r'$a+b$'), isTrue);
    });

    test('ignores currency-like dollars', () {
      expect(PaeMath.containsLatex(r'$5 and $10'), isFalse);
      expect(PaeMath.containsLatex(r'costs $5$ today'), isFalse);
      expect(PaeMath.containsLatex(r'$5.00$'), isFalse);
      expect(PaeMath.containsLatex('no math here'), isFalse);
    });

    test('protect extracts latex and display flags', () {
      final formulas = <PaeMathSnippet>[];
      final out = PaeMath.protect(
        r'inline $x$ and display $$y^2$$ and \[\frac{a}{b}\]',
        formulas,
      );

      expect(out, contains('[[pae-math-0]]'));
      expect(formulas, hasLength(3));
      expect(formulas[0], const PaeMathSnippet('x'));
      expect(formulas[1], const PaeMathSnippet(r'y^2', display: true));
      expect(
        formulas[2],
        const PaeMathSnippet(r'\frac{a}{b}', display: true),
      );
    });
  });

  group('PaeMath normalize / parse', () {
    test('normalizeLatex strips delimiters', () {
      expect(PaeMath.normalizeLatex(r'$x^2$'), r'x^2');
      expect(PaeMath.normalizeLatex(r'$$x^2$$'), r'x^2');
      expect(PaeMath.normalizeLatex(r'\(x^2\)'), r'x^2');
      expect(PaeMath.normalizeLatex(r'\[x^2\]'), r'x^2');
      expect(PaeMath.normalizeLatex(r'x^2'), r'x^2');
    });

    test('parseSnippet detects display delimiters', () {
      expect(
        PaeMath.parseSnippet(r'$$x$$'),
        const PaeMathSnippet('x', display: true),
      );
      expect(
        PaeMath.parseSnippet(r'\[x\]'),
        const PaeMathSnippet('x', display: true),
      );
      expect(PaeMath.parseSnippet(r'$x$'), const PaeMathSnippet('x'));
      expect(
        PaeMath.parseSnippet(r'$x$', display: true),
        const PaeMathSnippet('x', display: true),
      );
    });
  });

  group('PaeMath HTML', () {
    test('formulaToHtml inline vs display', () {
      final inline = PaeMath.formulaToHtml(r'x^2');
      expect(inline, contains('class="math-tex"'));
      expect(inline, contains('data-latex="x^2"'));
      expect(inline, contains(r'\(x^2\)'));
      expect(inline, isNot(contains('data-display')));

      final display = PaeMath.formulaToHtml(r'x^2', display: true);
      expect(display, contains('data-display="true"'));
      expect(display, contains(r'\[x^2\]'));
    });

    test('snippetsFromHtml reads span data-latex and display', () {
      final html = PaeMath.formulaToHtml(r'a+b', display: true);
      final snippets = PaeMath.snippetsFromHtml('<p>$html</p>');
      expect(snippets, hasLength(1));
      expect(snippets.first.latex, 'a+b');
      expect(snippets.first.display, isTrue);
    });

    test('snippetsFromHtml reads KaTeX annotation', () {
      const html = '''
<div class="katex">
  <annotation encoding="application/x-tex">x^2</annotation>
</div>
''';
      final snippets = PaeMath.snippetsFromHtml(html);
      expect(snippets.map((s) => s.latex), ['x^2']);
    });

    test('snippetsFromHtml reads MathJax display script', () {
      const html =
          '<script type="math/tex; mode=display">E=mc^2</script>';
      final snippets = PaeMath.snippetsFromHtml(html);
      expect(snippets, hasLength(1));
      expect(snippets.first.latex, 'E=mc^2');
      expect(snippets.first.display, isTrue);
    });

    test('snippetsFromHtml reads MathML alttext', () {
      const html = '<math alttext="a_i"></math>';
      final snippets = PaeMath.snippetsFromHtml(html);
      expect(snippets.map((s) => s.latex), ['a_i']);
    });

    test('protect + restorePlaceholders roundtrip', () {
      final formulas = <PaeMathSnippet>[];
      final protected = PaeMath.protect(r'see $x_i$ please', formulas);
      final html = PaeMath.restorePlaceholders(protected, formulas);
      expect(html, contains('data-latex="x_i"'));
      expect(html, contains(r'\(x_i\)'));
    });

    test('fromPlainText turns delimiters into spans', () {
      final html = PaeHtml.fromPlainText(r'Value is $x^2$.');
      expect(html, contains('math-tex'));
      expect(html, contains('data-latex="x^2"'));
    });

    test('fromMarkdown protects underscores inside math', () {
      final html = PaeHtml.fromMarkdown(r'Hello $x_i$ world');
      expect(html, contains('data-latex="x_i"'));
      expect(html, isNot(contains('<em>')));
    });
  });

  group('PaeMathSnippet embed value', () {
    test('inline stays a string; display becomes a map', () {
      expect(const PaeMathSnippet('x').toEmbedValue(), 'x');
      expect(
        const PaeMathSnippet('x', display: true).toEmbedValue(),
        {'latex': 'x', 'display': true},
      );
    });

    test('fromEmbedValue accepts string and map', () {
      expect(
        PaeMathSnippet.fromEmbedValue('x'),
        const PaeMathSnippet('x'),
      );
      expect(
        PaeMathSnippet.fromEmbedValue({'latex': 'y', 'display': true}),
        const PaeMathSnippet('y', display: true),
      );
    });
  });
}
