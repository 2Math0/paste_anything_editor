import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;

import 'math_codec.dart';

/// Renders a LaTeX formula; shows the raw LaTeX in red if it doesn't parse.
class MathFormulaView extends StatelessWidget {
  const MathFormulaView(
    this.latex, {
    super.key,
    this.display = false,
    this.textStyle,
  });

  final String latex;
  final bool display;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? DefaultTextStyle.of(context).style;
    return Math.tex(
      latex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: style,
      onErrorFallback: (_) => Text(
        latex,
        style: style.copyWith(color: Colors.red.shade700),
      ),
    );
  }
}

/// `customWidgetBuilder` for [HtmlWidget] so saved formula spans render as
/// equations instead of `\(...\)` text:
///
/// ```dart
/// HtmlWidget(html, customWidgetBuilder: mathHtmlWidgetBuilder)
/// ```
Widget? mathHtmlWidgetBuilder(dom.Element element) {
  final latex = MathCodec.latexOf(element);
  if (latex == null) return null;
  return InlineCustomWidget(child: MathFormulaView(latex));
}
