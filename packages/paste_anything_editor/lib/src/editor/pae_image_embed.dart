import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:paste_anything/paste_anything.dart';

import '../codec/pae_quill_codec.dart';

/// Renders a Quill `image` block embed holding an `http(s):` URL or a
/// `data:image/...;base64,` URI.
class PaeImageEmbedBuilder extends EmbedBuilder {
  const PaeImageEmbedBuilder({this.maxHeight = 360});

  final double maxHeight;

  @override
  String get key => PaeQuillCodec.imageEmbedType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final src = embedContext.node.value.data.toString();
    final controller = embedContext.controller;
    final offset = embedContext.node.documentOffset;

    final image = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: PaeImageView(src),
    );
    if (embedContext.readOnly) return image;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          image,
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              elevation: 1,
              borderRadius: BorderRadius.circular(6),
              child: IconButton(
                tooltip: 'Remove image',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => controller.replaceText(
                  offset,
                  1,
                  '',
                  TextSelection.collapsed(offset: offset),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays an image from an `http(s):` URL or a `data:` URI, with a
/// placeholder when it can't be loaded (bad data, CORS, 404).
class PaeImageView extends StatelessWidget {
  const PaeImageView(this.src, {super.key, this.fit = BoxFit.contain});

  final String src;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(src.trim());
    final data = uri?.data;
    if (data != null) {
      try {
        return Image.memory(
          data.contentAsBytes(),
          fit: fit,
          errorBuilder: (_, __, ___) => _broken(context),
        );
      } catch (_) {
        return _broken(context);
      }
    }
    if (uri == null || !PaeHtml.isRenderableImageSource(src)) {
      return _broken(context);
    }
    return Image.network(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => _broken(context),
    );
  }

  Widget _broken(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              src.startsWith('data:') ? 'Image could not be shown' : src,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback for embed types without a builder (e.g. `video` from pasted
/// HTML), so an unsupported embed shows a chip instead of breaking the editor.
class PaeUnknownEmbedBuilder extends EmbedBuilder {
  const PaeUnknownEmbedBuilder();

  @override
  String get key => '__unknown__';

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final type = embedContext.node.value.type;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '[$type]',
        style: (embedContext.textStyle).copyWith(color: Colors.grey.shade700),
      ),
    );
  }
}
