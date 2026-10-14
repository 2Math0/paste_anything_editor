# paste_anything

The copy-paste brain of
[paste_anything_editor](https://pub.dev/packages/paste_anything_editor),
for teams that already have their own editor.

It reads the clipboard on the **web** and turns whatever is there (Word,
Excel, Google Docs, web pages, Markdown, LaTeX or an image) into clean HTML
that any editor can insert.

> Pure Dart, web only. No Flutter or editor dependency: only `web`, `html`
> and `markdown`.

## Install

```sh
dart pub add paste_anything
```

## Paste into your editor

Implement `PaeTarget` on your editor and let `PaePaster` decide what to
insert:

```dart
import 'package:paste_anything/paste_anything.dart';

class MyEditorTarget implements PaeTarget {
  @override
  void insertHtml(String html) => myEditor.insertHtml(html);

  @override
  void insertText(String text) => myEditor.insertText(text);

  @override
  Future<void> insertImage(PaeImage image) async =>
      myEditor.insertImage(await upload(image.bytes, image.mimeType));
}

// On Ctrl/Cmd+V or your paste button:
await const PaePaster(allowImages: true).pasteInto(MyEditorTarget());
```

`PaePaster` picks, in order:

1. An image, when that's all the clipboard holds (only if `allowImages`).
2. Rich HTML from Word, Excel, Google Docs or web pages, cleaned up.
3. Text that is HTML source, LaTeX (`$x^2$`, `\(..\)`, `$$..$$`) or
   Markdown, converted to HTML.
4. Plain text.

Prefer to handle the result yourself? Use `resolve`:

```dart
final content = const PaePaster().resolve(await PaeClipboard.read());
switch (content) {
  case PaeHtmlContent(:final html): ...
  case PaeTextContent(:final text): ...
  case PaeImageContent(:final image): ...
  case PaeEmptyContent(): ...
}
```

## Copy with formatting

```dart
await PaeClipboard.writeHtml(html, plainText: PaeHtml.toPlainText(html));
```

## Building blocks

- `PaeClipboard`: `read()` (HTML, text and image in one call), `readText()`,
  `writeHtml()`, `writeText()`, `waitForFocus()`.
- `PaeHtml`: `normalize()` cleans any HTML, plus `fromMarkdown()`,
  `fromPlainText()`, `toPlainText()` and detection helpers.
- `PaeMath`: finds formulas from KaTeX, MathJax, MathML and `$..$` text.
  They're stored as `<span class="math-tex" data-latex="...">`, which KaTeX
  and MathJax can render. Also `copyFormula()` and `readFormula()`.

## Good to know

- The first read shows the browser's clipboard permission prompt. `read()`
  waits for the page to regain focus and then retries.
- `normalize()` removes scripts, embeds, event handlers and `javascript:`
  links. Still sanitize HTML on your server before showing it to other users.
- Word's local `file:///` images can't be read by a browser and are dropped.

## License

MIT, see [LICENSE](LICENSE).
