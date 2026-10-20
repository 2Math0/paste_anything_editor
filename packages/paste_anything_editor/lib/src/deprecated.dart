// Pre-0.4 names, kept so existing code compiles. Removed in 1.0.

import 'dart:typed_data';

import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as dom;
import 'package:paste_anything/paste_anything.dart';

import 'codec/pae_quill_codec.dart';
import 'editor/pae_editor.dart';
import 'editor/pae_editor_controller.dart';
import 'editor/pae_image_embed.dart';
import 'editor/pae_quill_localizations_scope.dart';
import 'editor/pae_table_embed.dart';
import 'math/pae_math_dialog.dart';
import 'math/pae_math_embed.dart';
import 'math/pae_math_keyboard.dart';
import 'math/pae_math_symbols.dart';
import 'math/pae_math_theme.dart';
import 'math/pae_math_view.dart';

// Editor -----------------------------------------------------------------------

@Deprecated('Use PaeEditor')
typedef RichHtmlEditor = PaeEditor;
@Deprecated('Use PaeEditorController')
typedef RichHtmlEditorController = PaeEditorController;
@Deprecated('Use PaeNotifier')
typedef RichEditorNotifier = PaeNotifier;
@Deprecated('Use PaeImagePasteHandler')
typedef ImagePasteHandler = PaeImagePasteHandler;
@Deprecated('Use PaeTableEmbedBuilder')
typedef HtmlTableEmbedBuilder = PaeTableEmbedBuilder;
@Deprecated('Use PaeImageEmbedBuilder')
typedef RichImageEmbedBuilder = PaeImageEmbedBuilder;
@Deprecated('Use PaeImageView')
typedef RichImageView = PaeImageView;
@Deprecated('Use PaeUnknownEmbedBuilder')
typedef UnknownEmbedBuilder = PaeUnknownEmbedBuilder;
@Deprecated('Use PaeQuillLocalizationsScope')
typedef QuillLocalizationsScope = PaeQuillLocalizationsScope;

// Math UI ----------------------------------------------------------------------

@Deprecated('Use PaeMathEmbedBuilder')
typedef MathFormulaEmbedBuilder = PaeMathEmbedBuilder;
@Deprecated('Use PaeMathKeyboard')
typedef MathKeyboard = PaeMathKeyboard;
@Deprecated('Use PaeMathInputMode')
typedef MathInputMode = PaeMathInputMode;
@Deprecated('Use PaeMathDialog')
typedef MathInputDialog = PaeMathDialog;
@Deprecated('Use PaeMathPanel')
typedef MathInputPanel = PaeMathPanel;
@Deprecated('Use PaeMathTheme')
typedef MathPanelTheme = PaeMathTheme;
@Deprecated('Use PaeMathLabels')
typedef MathPanelLabels = PaeMathLabels;
@Deprecated('Use PaeMathView')
typedef MathFormulaView = PaeMathView;
@Deprecated('Use PaeMathInsertion')
typedef MathInsertion = PaeMathInsertion;
@Deprecated('Use PaeMathSymbolInsertion')
typedef MathSymbolInsertion = PaeMathSymbolInsertion;
@Deprecated('Use PaeMathFormulaInsertion')
typedef MathFormulaInsertion = PaeMathFormulaInsertion;
@Deprecated('Use PaeMathSymbol')
typedef MathSymbol = PaeMathSymbol;
@Deprecated('Use PaeMathSymbolGroup')
typedef MathSymbolGroup = PaeMathSymbolGroup;
@Deprecated('Use PaeMathTemplate')
typedef MathTemplate = PaeMathTemplate;
@Deprecated('Use kPaeMathTemplates')
const kMathTemplates = kPaeMathTemplates;
@Deprecated('Use kPaeMathSymbolGroups')
const kMathSymbolGroups = kPaeMathSymbolGroups;
@Deprecated('Use paeMathHtmlBuilder')
const mathHtmlWidgetBuilder = paeMathHtmlBuilder;

// Clipboard (now in package:paste_anything) ------------------------------------

@Deprecated('Use PaeClip')
typedef ClipboardSnapshot = PaeClip;
@Deprecated('Use PaeImage')
typedef ClipboardImage = PaeImage;

@Deprecated('Use PaeClipboard.read')
Future<PaeClip> readClipboard() => PaeClipboard.read();

@Deprecated('Use PaeClipboard.readHtml')
Future<String?> readClipboardHtml() => PaeClipboard.readHtml();

@Deprecated('Use PaeClipboard.readText')
Future<String?> readClipboardText() => PaeClipboard.readText();

@Deprecated('Use PaeClipboard.writeHtml')
Future<bool> writeClipboardHtml(String html, {required String plainText}) =>
    PaeClipboard.writeHtml(html, plainText: plainText);

@Deprecated('Use PaeClipboard.waitForFocus')
Future<bool> waitForDocumentFocus({
  Duration timeout = const Duration(seconds: 3),
}) =>
    PaeClipboard.waitForFocus(timeout: timeout);

// Codecs -----------------------------------------------------------------------

@Deprecated('Use PaeHtml (cleanup) and PaeQuillCodec (Delta)')
abstract final class RichHtmlCodec {
  static const String tableEmbedType = PaeQuillCodec.tableEmbedType;
  static const String imageEmbedType = PaeQuillCodec.imageEmbedType;

  static bool looksLikeHtml(String text) => PaeHtml.looksLikeHtml(text);
  static bool looksLikeMarkdown(String text) => PaeHtml.looksLikeMarkdown(text);
  static bool isRenderableImageSource(String src) =>
      PaeHtml.isRenderableImageSource(src);
  static bool hasVisibleContent(String html, {bool countImages = false}) =>
      PaeHtml.hasVisibleContent(html, countImages: countImages);
  static bool isCodeEditorHtml(String html) => PaeHtml.isCodeEditorHtml(html);
  static String markdownToHtml(String markdown) =>
      PaeHtml.fromMarkdown(markdown);
  static Delta htmlToDelta(String html, {bool keepImages = true}) =>
      PaeQuillCodec.htmlToDelta(html, keepImages: keepImages);
  static String deltaToHtml(Delta delta) => PaeQuillCodec.deltaToHtml(delta);
  static String sanitizeTable(dom.Element table) =>
      PaeHtml.sanitizeTable(table);
  static String? sanitizeTableSource(String source) =>
      PaeHtml.sanitizeTableSource(source);
}

@Deprecated('Use PaeMath; the Delta embed type is PaeQuillCodec.mathEmbedType')
abstract final class MathCodec {
  static const String embedType = PaeQuillCodec.mathEmbedType;
  static const String cssClass = PaeMath.cssClass;

  static String normalizeLatex(String text) => PaeMath.normalizeLatex(text);
  static bool containsLatex(String text) => PaeMath.containsLatex(text);
  static String protect(String text, List<String> formulas) {
    final snippets = <PaeMathSnippet>[];
    final out = PaeMath.protect(text, snippets);
    formulas.addAll(snippets.map((s) => s.latex));
    return out;
  }

  static String restorePlaceholders(String html, List<String> formulas) =>
      PaeMath.restorePlaceholders(
        html,
        formulas.map(PaeMathSnippet.new).toList(),
      );
  static String plainTextToHtml(String text) => PaeHtml.fromPlainText(text);
  static String formulaToHtml(String latex) => PaeMath.formulaToHtml(latex);
  static String? latexOf(dom.Element el) => PaeMath.latexOf(el);
  static List<String> extractFormulas(dom.Element root) =>
      PaeMath.extractFormulas(root).map((s) => s.latex).toList();
  static List<String> formulasFromHtml(String html) =>
      PaeMath.formulasFromHtml(html);
  static Future<void> copySymbol(String char) => PaeClipboard.writeText(char);
  static Future<void> copyFormula(String latex) => PaeMath.copyFormula(latex);
  static Future<void> copyLatex(String latex) => PaeClipboard.writeText(latex);
  static Future<String?> readFormulaFromClipboard() => PaeMath.readFormula();
}

/// Pre-0.4 `insertImageBytes`; `insertImage` now takes a [PaeImage] and the
/// URL variant is `insertImageUrl`.
extension PaeEditorControllerDeprecated on PaeEditorController {
  @Deprecated('Use insertImage(PaeImage(bytes, mimeType))')
  Future<void> insertImageBytes(Uint8List bytes, String mimeType) =>
      insertImage(PaeImage(bytes, mimeType));
}
