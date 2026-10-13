## 0.1.0

- Initial release.
- `RichHtmlEditor` / `RichHtmlEditorController`: Quill editor that loads and
  saves HTML, with copy/paste toolbar.
- Rich paste from Word, Excel, Google Docs, web pages, code editors, HTML
  source and Markdown (colors, fonts, bold/italic/underline/strike, lists,
  headings, links, tables).
- Tables as editable block embeds.
- Math: Unicode symbol palette, LaTeX formulas rendered as equations, paste
  from KaTeX / MathJax / MathML / `$..$` text, copy as HTML + LaTeX.
- Opt-in image paste (`allowImagePaste`) with upload callback or `data:` URI
  fallback; unsupported embeds render a placeholder instead of crashing.
