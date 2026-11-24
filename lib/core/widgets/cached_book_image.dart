import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedBookImage extends StatelessWidget {
  const CachedBookImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth = 480,
    this.placeholderColor,
  });

  final String url;
  final BoxFit fit;
  final int cacheWidth;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = placeholderColor ?? colors.surfaceContainerHighest;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: 720,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => ColoredBox(
        color: background,
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: colors.primary.withValues(alpha: .65),
            size: 30,
          ),
        ),
      ),
      errorWidget: (context, url, error) => ColoredBox(
        color: background,
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: colors.onSurfaceVariant,
            size: 30,
          ),
        ),
      ),
    );
  }
}
