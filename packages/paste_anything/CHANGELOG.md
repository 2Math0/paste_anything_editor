## 0.1.1

- `PaeMathSnippet` with display/inline flag; `$$…$$` / `\[…\]` become display HTML
  (`data-display="true"`).
- Wider `$…$` detection with currency safeguards; MathJax scripts in `<head>`
  are found; `snippetsFromHtml` / `parseSnippet` helpers.

## 0.1.0

- Initial release: the copy-paste core of `paste_anything_editor` as a pure
  Dart, web-only package.
- `PaeClipboard`: single-call clipboard read (HTML, text, image) with retry
  after the permission prompt; HTML and text writes.
- `PaeHtml.normalize`: cleans Word, Excel, Outlook, Google Docs and web page
  HTML; strips scripts, embeds, event handlers and `javascript:` URLs.
- `PaeHtml.fromMarkdown`, `fromPlainText`, `toPlainText`, detection helpers.
- `PaeMath`: formula detection (KaTeX, MathJax, MathML, `$..$`) and
  clipboard helpers.
- `PaeTarget` and `PaePaster`: plug the paste logic into any editor.
