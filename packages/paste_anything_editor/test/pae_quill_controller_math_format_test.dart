import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_anything_editor/paste_anything_editor.dart';

void main() {
  group('PaeQuillController math format guard', () {
    test('blocks format when selection covers a formula', () {
      final doc = Document();
      doc.insert(0, 'Hi ');
      doc.insert(3, Embeddable(PaeQuillCodec.mathEmbedType, r'x^2'));
      doc.insert(4, ' there');

      var blocked = 0;
      final c = PaeQuillController(
        document: doc,
        selection: const TextSelection(baseOffset: 3, extentOffset: 4),
        onMathFormatBlocked: () => blocked++,
      );

      expect(c.rangeContainsMath(3, 1), isTrue);
      c.formatSelection(Attribute.bold);
      expect(blocked, 1);
    });

    test('allows format on plain text', () {
      final doc = Document()..insert(0, 'plain');
      var blocked = 0;
      final c = PaeQuillController(
        document: doc,
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        onMathFormatBlocked: () => blocked++,
      );

      expect(c.rangeContainsMath(0, 5), isFalse);
      c.formatSelection(Attribute.bold);
      expect(blocked, 0);
    });
  });
}
