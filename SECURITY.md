# Security Policy

## Supported versions

Only the latest published version receives fixes.

## Reporting a vulnerability

Please report security issues privately (do not open a public issue) via the
repository's "Report a vulnerability" button, or by email to the maintainer
listed on pub.dev. Include steps to reproduce and the affected version. You
should get a reply within 7 days.

## Scope notes

- Pasted HTML is converted to a Quill Delta, so scripts, styles, event
  handlers and unknown tags are dropped. Tables are re-serialized keeping only
  `colspan`, `rowspan`, a small set of CSS properties and image
  `src`/`alt`/`width`/`height`.
- `getText()` returns HTML built from the Delta. If you render it outside this
  package (e.g. in a browser `innerHTML`), sanitize it on your server as you
  would any user content.
- Pasted images are kept only for `http(s):` and `data:image/` sources and
  only when `allowImagePaste` is enabled.
