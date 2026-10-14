import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:paste_anything_editor/paste_anything_editor.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        // App-wide math keyboard/dialog style; per-use `theme:` overrides it.
        extensions: const [PaeMathTheme(dialogBorderRadius: 20)],
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
  final controller = PaeEditorController(
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
        // Room to scroll content above the docked math keyboard.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 320),
        children: [
          PaeEditor(
            controller: controller,
            initialText: r'<p>Paste from Word, Google Docs or Excel. '
                r'Euler: <span class="math-tex" data-latex="e^{i\pi}+1=0">'
                r'\(e^{i\pi}+1=0\)</span></p>',
            height: 400,
            onChanged: (value) => setState(() => html = value ?? ''),
            mathTheme: const PaeMathTheme(
              headerColor: Color(0xFF1E3A8A),
              headerForegroundColor: Colors.white,
              actionColor: Color(0xFF1E3A8A),
            ),
            mathLabels: const PaeMathLabels(
              title: 'Equations',
              keyboardTitle: 'Equations',
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.functions),
            label: const Text('Standalone math dialog'),
            onPressed: () async {
              final result = await PaeMathDialog.show(
                context,
                theme: const PaeMathTheme(seedColor: Colors.teal),
              );
              switch (result) {
                case PaeMathSymbolInsertion(:final char):
                  await PaeClipboard.writeText(char);
                case PaeMathFormulaInsertion(:final latex):
                  await PaeMath.copyFormula(latex);
                case null:
                  break;
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Preview (HtmlWidget):'),
          HtmlWidget(html, customWidgetBuilder: paeMathHtmlBuilder),
        ],
      ),
    );
  }
}
