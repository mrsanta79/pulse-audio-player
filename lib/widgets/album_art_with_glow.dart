import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';

/// Album artwork, optionally haloed in its own dominant colour.
///
/// Give [size] whenever the drawn size is known: it is used both to lay the
/// art out and to decode it at the right resolution. Without it the widget
/// fills its parent and measures itself, because decoding a 3000px bitmap for
/// a 130px grid cell costs megabytes per cover.
class AlbumArtWithGlow extends StatelessWidget {
  const AlbumArtWithGlow({
    super.key,
    required this.artHash,
    this.size,
    this.borderRadius = AppRadii.albumArt,
    this.showGlow = true,
    this.heroTag,
  });

  final String? artHash;
  final double? size;
  final double borderRadius;
  final bool showGlow;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final fixedSize = size;

    Widget art = fixedSize != null
        ? SizedBox(
            width: fixedSize,
            height: fixedSize,
            child: _clipped(context, fixedSize),
          )
        : AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.biggest.shortestSide;
                return _clipped(context, side.isFinite ? side : null);
              },
            ),
          );

    if (showGlow) {
      art = _Glow(
        artHash: artHash,
        radius: borderRadius,
        sized: fixedSize != null,
        child: art,
      );
    }
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    return art;
  }

  Widget _clipped(BuildContext context, double? side) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _Art(
        artHash: artHash,
        side: side,
        // A tighter corner means a small inline thumbnail, which needs a
        // smaller stand-in icon.
        iconSize: borderRadius > 16 ? 48 : 20,
      ),
    );
  }
}

class _Art extends ConsumerWidget {
  const _Art({
    required this.artHash,
    required this.side,
    required this.iconSize,
  });

  final String? artHash;

  /// Logical width the art is drawn at, used to pick a decode resolution.
  final double? side;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final bytes = ref.watch(albumArtProvider(artHash)).valueOrNull;
    if (bytes == null) return _placeholder(palette);

    // Decode to roughly the display size rather than holding full-resolution
    // bitmaps: large covers are several MB decoded, and a grid shows dozens.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = side == null ? null : (side! * dpr).ceil();

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, _, __) => _placeholder(palette),
    );
  }

  Widget _placeholder(AppPalette palette) {
    return Container(
      color: palette.surfaceHighlight,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: palette.textSecondary,
          size: iconSize,
        ),
      ),
    );
  }
}

/// The artwork's halo. Its own consumer so resolving the colour, which needs a
/// decode and a quantise pass, doesn't hold up the artwork itself.
class _Glow extends ConsumerWidget {
  const _Glow({
    required this.artHash,
    required this.radius,
    required this.sized,
    required this.child,
  });

  final String? artHash;
  final double radius;

  /// Small inline art gets a tight halo; a full-width cover gets a wide one.
  final bool sized;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final color =
        ref.watch(glowColorProvider(artHash)).valueOrNull ??
        palette.glowFallback;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: sized ? 24 : 56,
            spreadRadius: sized ? 0 : 4,
          ),
        ],
      ),
      child: child,
    );
  }
}
