# Security Policy

## Supported versions

Only the latest published version receives fixes.

## Reporting a vulnerability

Please report security issues privately (do not open a public issue) via the
repository's "Report a vulnerability" button, or by email to the maintainer
listed on pub.dev. Include steps to reproduce and the affected version. You
should get a reply within 7 days.

## Scope notes

- `PaeHtml.normalize` removes comments, `<script>`, `<style>`, embeds
  (`iframe`, `object`, `embed`, ...), `on*` event handlers and
  `javascript:` / `vbscript:` / `data:` URLs (except `data:image/` images).
- It is a paste cleaner, not a full HTML sanitizer. Sanitize HTML on your
  server before rendering content from one user to others.
- Pasted images are kept only for `http(s):` and `data:image/` sources and
  only when `allowImages` is enabled.
