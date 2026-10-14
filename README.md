# paste_anything_editor

Copy and paste **anything** into a Flutter web app and keep its formatting:
Word, Excel, Google Docs, web pages, Markdown, HTML source, tables, math
formulas and images. Built on [flutter_quill](https://pub.dev/packages/flutter_quill);
loads and saves plain HTML strings, so it drops into APIs that already store
HTML.

## Features

- **Rich paste** (Ctrl/Cmd+V or the paste button)
  - Word / Outlook / Excel: bold, italic, underline, strike, colors,
    highlights, font family, headings, lists, links, tables.
  - Google Docs: CSS-based bold/italic/underline/strike are converted.
  - Web pages and HTML source text.
  - Markdown (GitHub flavored, incl. tables).
  - VS Code / JetBrains: pasted as plain code text, not styled HTML.
- **Rich copy**: writes `text/html` + `text/plain` so other editors receive
  formatted content.
- **Tables** as editable block embeds.
- **Math**
  - Unicode symbol palette (operators, Greek, sets, arrows, ...).
  - LaTeX formulas rendered as equations (`flutter_math_fork`).
  - Paste from KaTeX, MathJax, MathML, or text with `$..$`, `$$..$$`,
    `\(..\)`, `\[..\]`.
  - Stored as `<span class="math-tex" data-latex="...">\(...\)</span>`
    (KaTeX / MathJax compatible).
  - Standalone `MathInputPanel` / `MathInputDialog` usable outside the editor.
- **Images (opt-in)**: screenshots, "Copy image", and `<img>` in pasted HTML.
- Unsupported embeds render a placeholder instead of crashing the editor.

## Install

```sh
flutter pub add paste_anything_editor
```

A runnable demo is in [`example/`](example/) (`cd example && flutter run -d chrome`).

## Usage

```dart
import 'package:paste_anything_editor/paste_anything_editor.dart';

final controller = RichHtmlEditorController();

RichHtmlEditor(
  controller: controller,
  initialText: '<p>Hello</p>',
  onChanged: (html) => print(html),
);

final html = await controller.getText(); // save
controller.setText(html);                // load
```

### Images

Image paste is **off** by default (pasted images are dropped).

```dart
// data: URIs embedded in the HTML
RichHtmlEditorController(allowImagePaste: true);

// or upload and store the returned URL (return null to drop the image)
RichHtmlEditorController(
  allowImagePaste: true,
  onImagePaste: (bytes, mimeType) async => uploadAndGetUrl(bytes, mimeType),
);
```

Only `http(s):` and `data:image/` sources are kept; Word's local `file:///`
images can't be read by a browser. Remote images must allow CORS to display
in Flutter web.

### Math outside the editor

```dart
final result = await MathInputDialog.show(context);
switch (result) {
  case MathSymbolInsertion(:final char): ...
  case MathFormulaInsertion(:final latex): ...
  case null: break;
}

MathFormulaView(r'\frac{a}{b}');
```

### Math dialog theming

Unset values come from the app's Material `ColorScheme`, so the dialog matches
your theme by default. Customize app-wide:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [MathPanelTheme(seedColor: Colors.teal)],
  ),
);
```

or per use (editor, dialog, embedded panel), overriding the app-wide values:

```dart
RichHtmlEditor(
  controller: controller,
  mathTheme: const MathPanelTheme(
    headerColor: Color(0xFF1E3A8A),
    headerForegroundColor: Colors.white,
    actionColor: Color(0xFF1E3A8A),
    symbolTileColor: Color(0xFFF1F5F9),
    dialogBorderRadius: 16,
  ),
  mathLabels: const MathPanelLabels(title: 'Equations', insert: 'Add'),
);

MathInputDialog.show(
  context,
  theme: const MathPanelTheme(seedColor: Colors.deepPurple),
  showSymbolsTab: false,
  templates: [MathTemplate('Fraction', r'\frac{a}{b}', 'a over b')],
);

MathInputPanel(theme: MathPanelTheme(colorScheme: myScheme));
```

`MathPanelTheme` covers background, header, title, tabs, category chips,
template chips, symbol tiles, LaTeX field, preview, primary action, barrier,
radii, elevation, dialog size / padding, tile and font sizes.

To render saved formulas in `HtmlWidget`:

```dart
HtmlWidget(html, customWidgetBuilder: mathHtmlWidgetBuilder);
```

### Lower-level API

- `RichHtmlCodec`: `htmlToDelta`, `deltaToHtml`, `markdownToHtml`,
  `sanitizeTable`, detection helpers.
- `MathCodec`: formula HTML, LaTeX detection, clipboard helpers.
- `readClipboard()` / `writeClipboardHtml()`: async Clipboard API access.

## Platform notes

- Rich clipboard (HTML / image flavors) uses the browser async Clipboard API,
  so it works on **web**. Chrome asks the user for clipboard permission on
  the first rich paste. On other platforms the editor falls back to plain
  text paste.
- The first rich paste shows the browser's clipboard permission prompt;
  the editor waits for the page to regain focus after it and retries.
- Requires Flutter >= 3.27.

## Dependency policy

Dependencies use wide ranges (a full major version, or the 0.x minor for
pre-1.0 packages) instead of exact pins or `any`, so apps on different
Flutter versions can resolve them, while pub.dev's "lowest versions" check
still passes. Lower bounds are verified with `flutter pub downgrade` +
`flutter analyze`.

`flutter_quill` 11.6.0 is the first release that compiles on Flutter 3.44
(`TextInputClient.onFocusReceived`). Pub picks it automatically on 3.44+; if
your lock file holds an older 11.x, run `flutter pub upgrade flutter_quill`.

`flutter_math_fork` 0.7.4 requires Flutter >= 3.35 but does not declare it.
Apps on older Flutter should pin it:

```yaml
dependencies:
  flutter_math_fork: 0.7.3
```

## License

MIT, see [LICENSE](LICENSE).
