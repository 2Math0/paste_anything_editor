import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:paste_anything_editor/paste_anything_editor.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        // App-wide math dialog style; per-use `theme:` values override it.
        extensions: const [MathPanelTheme(dialogBorderRadius: 20)],
      ),
      home: const ExamplePage(),
    ),
  );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final controller = RichHtmlEditorController(
    allowImagePaste: true,
    // Upload and return a URL; without this, images are stored as data: URIs.
    // onImagePaste: (bytes, mimeType) async => myUpload(bytes, mimeType),
  );
  String html = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('paste_anything_editor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RichHtmlEditor(
            controller: controller,
            initialText: r'<p>Paste from Word, Google Docs or Excel. '
                r'Euler: <span class="math-tex" data-latex="e^{i\pi}+1=0">'
                r'\(e^{i\pi}+1=0\)</span></p>',
            height: 400,
            onChanged: (value) => setState(() => html = value ?? ''),
            mathTheme: const MathPanelTheme(
              headerColor: Color(0xFF1E3A8A),
              headerForegroundColor: Colors.white,
              actionColor: Color(0xFF1E3A8A),
            ),
            mathLabels: const MathPanelLabels(title: 'Equations'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.functions),
            label: const Text('Standalone math dialog'),
            onPressed: () async {
              final result = await MathInputDialog.show(
                context,
                theme: const MathPanelTheme(seedColor: Colors.teal),
              );
              switch (result) {
                case MathSymbolInsertion(:final char):
                  await MathCodec.copySymbol(char);
                case MathFormulaInsertion(:final latex):
                  await MathCodec.copyFormula(latex);
                case null:
                  break;
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Preview (HtmlWidget):'),
          HtmlWidget(html, customWidgetBuilder: mathHtmlWidgetBuilder),
        ],
      ),
    );
  }
}
