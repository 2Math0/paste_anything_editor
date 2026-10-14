# paste_anything example

Wire the paste logic into any editor by implementing `PaeTarget`:

```dart
import 'package:paste_anything/paste_anything.dart';

class MyEditorTarget implements PaeTarget {
  MyEditorTarget(this.editor);

  final MyEditor editor;

  @override
  void insertHtml(String html) => editor.insertHtml(html);

  @override
  void insertText(String text) => editor.insertText(text);

  @override
  void insertImage(PaeImage image) => editor.insertHtml(
        '<img src="${image.toDataUri()}">',
      );
}

Future<void> onPaste(MyEditor editor) async {
  final inserted = await const PaePaster(allowImages: true)
      .pasteInto(MyEditorTarget(editor));
  if (inserted is PaeEmptyContent) print('Nothing to paste');
}

Future<void> onCopy(String html) async {
  await PaeClipboard.writeHtml(html, plainText: PaeHtml.toPlainText(html));
}
```

Clean HTML without touching the clipboard:

```dart
final clean = PaeHtml.normalize(wordHtml, keepImages: false);
final fromMd = PaeHtml.fromMarkdown('# Title\n\n**bold** and $x^2$');
final formulas = PaeMath.formulasFromHtml(katexHtml); // ['x^2', ...]
```
