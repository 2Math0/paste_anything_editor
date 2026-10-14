/// Rich text editor for Flutter web with copy/paste that keeps formatting
/// (Word, Excel, Google Docs, Markdown, HTML, tables, math formulas, images)
/// and a math keyboard. Loads and saves HTML.
///
/// Re-exports `package:paste_anything`, the copy-paste core.
library;

export 'package:paste_anything/paste_anything.dart';

export 'src/codec/pae_quill_codec.dart';
export 'src/deprecated.dart';
export 'src/editor/pae_editor.dart';
export 'src/editor/pae_editor_controller.dart';
export 'src/editor/pae_image_embed.dart';
export 'src/editor/pae_quill_localizations_scope.dart';
export 'src/editor/pae_table_embed.dart';
export 'src/math/pae_math_dialog.dart';
export 'src/math/pae_math_embed.dart';
export 'src/math/pae_math_keyboard.dart';
export 'src/math/pae_math_symbols.dart';
export 'src/math/pae_math_theme.dart';
export 'src/math/pae_math_view.dart';
