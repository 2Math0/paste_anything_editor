# paste_anything_editor

A rich text editor for **Flutter web** that keeps formatting when you copy
and paste from Word, Excel, Google Docs, web pages, Markdown, tables, math
formulas and images.

It is built on [flutter_quill](https://pub.dev/packages/flutter_quill) and
works with plain HTML strings: load HTML in, get HTML out.

> Web only. Rich copy/paste uses the browser Clipboard API.
>
> Have your own editor? Use [paste_anything](https://pub.dev/packages/paste_anything),
> the copy-paste core of this package, with no Flutter or Quill dependency.

<p align="center">
  <img src="https://raw.githubusercontent.com/2Math0/paste_anything_editor/master/packages/paste_anything_editor/doc/images/math_keyboard.png" alt="Editor with pasted formulas, HTML preview and the docked math keyboard showing formula templates" width="720">
</p>

## Features

- **Paste with formatting** (Ctrl/Cmd+V or the paste button): bold, italic,
  underline, colors, fonts, headings, lists, links and tables from Word,
  Excel, Google Docs, web pages, HTML source and Markdown.
- **Copy with formatting**: other editors receive formatted HTML.
- **Math**: a docked math keyboard with symbols and formula templates, LaTeX
  formulas rendered as equations, and paste from KaTeX, MathJax, MathML or
  `$...$` text.
- **Images** (opt-in): screenshots, "Copy image" and images inside pasted
  HTML.

## Install

```sh
flutter pub add paste_anything_editor
```

A runnable demo lives in [`example/`](example/):

```sh
cd example && flutter run -d chrome
```

## Quick start

```dart
import 'package:paste_anything_editor/paste_anything_editor.dart';

final controller = PaeEditorController();

PaeEditor(
  controller: controller,
  initialText: '<p>Hello</p>',
  onChanged: (html) => print(html),
);

final html = await controller.getText(); // save
controller.setText(html);                // load
```

## Math keyboard

The **∑** toolbar button opens a math keyboard docked at the bottom of the
screen. The editor keeps focus, so you can click anywhere in the text to move
the cursor and keep tapping symbols, like an on-screen keyboard.

- Symbol tabs insert Unicode characters (operators, Greek, sets, arrows, ...).
- The **Formulas** tab inserts LaTeX templates such as fractions and roots.
  Click an inserted formula to edit it.
- **LaTeX editor** opens a dialog to type any formula with a live preview.
- Press **∑** again, or the hide button, to close it.

<p align="center">
  <img src="https://raw.githubusercontent.com/2Math0/paste_anything_editor/master/packages/paste_anything_editor/doc/images/latex_editor.png" alt="LaTeX editor dialog with formula templates, live preview and symbol palette" width="560">
</p>

Prefer a modal dialog instead?

```dart
PaeEditor(
  controller: controller,
  mathInputMode: PaeMathInputMode.dialog,
);
```

Formulas are saved as
`<span class="math-tex" data-latex="...">\(...\)</span>`, which KaTeX and
MathJax can render. To show saved HTML with formulas in `HtmlWidget`:

```dart
HtmlWidget(html, customWidgetBuilder: paeMathHtmlBuilder);
```

## Images

Pasted images are dropped unless you allow them.

```dart
// Keep images inline as base64 data: URIs.
PaeEditorController(allowImagePaste: true);

// Or upload them and store the returned URL (return null to drop).
PaeEditorController(
  allowImagePaste: true,
  onImagePaste: (bytes, mimeType) => uploadAndGetUrl(bytes, mimeType),
);
```

## Customize math colors and texts

By default the keyboard and dialog follow your app's Material `ColorScheme`.
Set a `PaeMathTheme` app-wide:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [PaeMathTheme(seedColor: Colors.teal)],
  ),
);
```

or for one editor, together with your own texts:

```dart
PaeEditor(
  controller: controller,
  mathTheme: const PaeMathTheme(
    headerColor: Color(0xFF1E3A8A),
    headerForegroundColor: Colors.white,
    keyboardHeight: 320,
  ),
  mathLabels: const PaeMathLabels(
    title: 'Equations',
    keyboardTitle: 'Equations',
  ),
);
```

Every color, radius and size is optional; unset values fall back to the
theme. The screenshot above uses exactly this navy header and the
`'Equations'` title.

## Math without the editor

Use the pieces on their own:

```dart
// Docked keyboard in your own layout.
PaeMathKeyboard(onSymbol: (char) => ..., onFormula: (latex) => ...);

// Modal dialog.
final result = await PaeMathDialog.show(context);
switch (result) {
  case PaeMathSymbolInsertion(:final char): ...
  case PaeMathFormulaInsertion(:final latex): ...
  case null: break;
}

// Render a formula.
PaeMathView(r'\frac{a}{b}');
```

## Use only the paste logic

This package re-exports
[paste_anything](https://pub.dev/packages/paste_anything), so its pieces are
available here too: `PaeClipboard`, `PaeHtml.normalize`, `PaeMath` and
`PaePaster`. `PaeEditorController` implements its `PaeTarget` interface.
If you don't need this editor, depend on `paste_anything` alone.

## Upgrading from 0.3

Names now start with `Pae` (`RichHtmlEditor` is now `PaeEditor`,
`MathPanelTheme` is now `PaeMathTheme`, ...). The old names still work but
are deprecated. One breaking change: `controller.insertImage(url)` is now
`controller.insertImageUrl(url)`.

## Good to know

- The first rich paste shows the browser's clipboard permission prompt. The
  editor waits for the page to regain focus and then pastes.
- Word's local `file:///` images can't be read by a browser. Remote images
  need CORS to display.
- Needs Flutter 3.27 or newer. On Flutter 3.44 or newer, `flutter_quill`
  must be 11.6.0 or newer (`flutter pub upgrade flutter_quill`).
- `flutter_math_fork` 0.7.4 needs Flutter 3.35 or newer. On older Flutter,
  pin `flutter_math_fork: 0.7.3` in your app.

## License

MIT, see [LICENSE](LICENSE).
