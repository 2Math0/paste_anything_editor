// ignore_for_file: experimental_member_use

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../codec/pae_quill_codec.dart';

/// [QuillController] that blocks character/block formatting when the
/// selection includes a LaTeX formula embed, and notifies via
/// [onMathFormatBlocked].
class PaeQuillController extends QuillController {
  PaeQuillController({
    required super.document,
    required super.selection,
    super.config,
    this.onMathFormatBlocked,
  });

  /// Called when the user tries to bold / size / font / etc. a formula.
  VoidCallback? onMathFormatBlocked;

  @override
  void formatText(
    int index,
    int len,
    Attribute? attribute, {
    bool shouldNotifyListeners = true,
  }) {
    if (len > 0 && rangeContainsMath(index, len)) {
      onMathFormatBlocked?.call();
      return;
    }
    super.formatText(
      index,
      len,
      attribute,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }

  /// Whether `[index, index + len)` overlaps a `math-formula` embed.
  bool rangeContainsMath(int index, int len) {
    if (len <= 0) return false;
    final end = index + len;
    var offset = 0;
    for (final op in document.toDelta().toList()) {
      final data = op.data;
      final opLen = data is String ? data.length : 1;
      final opEnd = offset + opLen;
      if (opEnd > index && offset < end) {
        if (data is Map && data.containsKey(PaeQuillCodec.mathEmbedType)) {
          return true;
        }
      }
      offset = opEnd;
      if (offset >= end) break;
    }
    return false;
  }
}
