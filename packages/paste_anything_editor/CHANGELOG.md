## 0.4.1

- **Math default theme:** when no `seedColor` / `colorScheme` is set, math UI
  uses a teal seed (`PaeMathTheme.defaultSeedColor`) so the keyboard and
  dialog match the standalone dialog look out of the box.
- **Editor theming:** `PaeEditorTheme` / `PaeEditorLabels` for border, copy /
  paste row, snackbar chrome and all toast strings; `onNotify` still replaces
  SnackBars entirely.
- **LaTeX formatting guard:** toolbar bold / size / font on a selected formula
  is blocked and shows a toast (`cannotFormatFormula`).
- **Display math:** `$$…$$` / `\[…\]` keep a display flag through HTML ↔ Delta;
  embeds render with `MathStyle.display` when flagged.
- **Wider `$…$` detection** (still skips currency like `$5`); matrix templates
  for `pmatrix` / `bmatrix` / `vmatrix`.
- **Dialog polish:** segmented tabs, clearer formula layout; shape knobs
  (`dialogShape`, `dialogBorderSide`, header icon, etc.).
- **Fix:** deactivated-ancestor assert when closing the standalone math dialog
  (safe `FocusNode` dispose + pop on next frame).
  Also: formula-only LaTeX editor no longer creates a [TabController] in
  `dispose` (lazy `late final` was the real crash).
- Example: one shared `PaeMathTheme` for the editor and the standalone dialog.
- Image paste remains **opt-in** via `PaeEditorController(allowImagePaste: true)`
  (default embeds as `data:` URIs; optional `onImagePaste` upload).

## 0.4.0


- The copy-paste logic moved to a new pure Dart package,
  [paste_anything](https://pub.dev/packages/paste_anything), for teams with
  their own editor. This package depends on it and re-exports it.
- Every public name now has the `Pae` prefix: `PaeEditor`,
  `PaeEditorController`, `PaeQuillCodec`, `PaeMathKeyboard`,
  `PaeMathDialog`, `PaeMathTheme`, `PaeMathLabels`, and so on. The old names
  still work but are deprecated and will be removed in 1.0.
- `PaeEditorController` implements `PaeTarget` and pastes through
  `PaePaster`.
- **Breaking:** `insertImage` now takes a `PaeImage`; the URL variant is
  `insertImageUrl(url)`. `insertImageBytes` is deprecated.
- Clipboard helpers are now `PaeClipboard` (`read`, `readText`, `writeHtml`,
  `writeText`, `waitForFocus`); HTML cleanup is `PaeHtml.normalize`.
- Pasted HTML is also stripped of event handlers and `javascript:` links
  before conversion.
- Repository is now a pub workspace (`packages/`).

## 0.3.0

- Math keyboard: the toolbar math button now opens a docked `MathKeyboard`
  at the bottom of the screen. The editor keeps focus, so you can move the
  cursor and keep tapping symbols or formula templates. Toggle it with the
  same button or hide it from its header.
- `RichHtmlEditor.mathInputMode`: `MathInputMode.keyboard` (default) or
  `MathInputMode.dialog` (previous behavior).
- `MathPanelTheme`: `keyboardHeight`, `keyboardMaxWidth`,
  `keyboardBorderRadius`. `MathPanelLabels`: `toolbarTooltip`,
  `keyboardTitle`, `formulasCategory`, `openLatexEditor`, `hideKeyboard`.
- The package is now declared web-only on pub.dev.
- Simpler README.

## 0.2.0

- Fix: first "paste with formatting" after granting clipboard permission
  failed with `NotAllowedError: Document is not focused`. HTML, text and
  images are now read in a single Clipboard API call, and the read is retried
  once the page regains focus.
- New `readClipboardText()` and `waitForDocumentFocus()`;
  `ClipboardSnapshot` now carries `text` and `isAvailable`.
- Math dialog theming: `MathPanelTheme` (Material `ThemeExtension`, app-wide
  or per use, `seedColor` / `colorScheme`, every color, radius, size) and
  `MathPanelLabels` (all texts).
- `MathInputDialog.show` / `MathInputPanel`: `theme`, `labels`,
  `symbolGroups`, `templates`, `showSymbolsTab`, `showFormulaTab`.
- `RichHtmlEditor`: `mathTheme`, `mathLabels`; formula editing opens the
  formula tab only.
- Fix: `MissingFlutterQuillLocalizationException` when the app doesn't add
  `FlutterQuillLocalizations.delegate`; the editor now provides it
  (`QuillLocalizationsScope`).
- `example/` is now a standalone Flutter web app (`flutter run -d chrome`).
- Docs: Flutter 3.44 needs `flutter_quill` >= 11.6.0.

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
