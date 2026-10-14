# Paste Anything

Copy and paste rich content on the web (Word, Excel, Google Docs, web pages,
Markdown, LaTeX formulas and images) without losing formatting.

| Package | Use it when |
| --- | --- |
| [paste_anything](packages/paste_anything) | You have your own editor and only need the copy-paste logic. Pure Dart, no Flutter. |
| [paste_anything_editor](packages/paste_anything_editor) | You want a ready-made Flutter web editor with a math keyboard. Built on `paste_anything`. |

## Development

This repository is a [pub workspace](https://dart.dev/tools/pub/workspaces):

```sh
flutter pub get                       # resolves every package at once
cd packages/paste_anything_editor/example && flutter run -d chrome
```

Publish `paste_anything` before `paste_anything_editor` when both change.
