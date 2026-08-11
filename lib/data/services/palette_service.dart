import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteService {
  /// Extracting a colour means decoding the artwork and quantising it, so
  /// results are cached. Bounded, and least-recently-used first out: a library
  /// with thousands of covers would otherwise hold a colour for every one of
  /// them for the life of the process.
  static const _maxCacheEntries = 256;

  final LinkedHashMap<String, Color> _cache = LinkedHashMap();

  /// Artwork is quantised at this width. Colour extraction doesn't need detail,
  /// and decoding a full-size cover for it is what made the first frame of a
  /// new track slow.
  static const _sampleWidth = 64;

  /// The glow colour extracted from album art, or null when there is no art or
  /// no colour could be read.
  ///
  /// Returning null rather than a fallback colour keeps this service free of
  /// theme knowledge (it has no `BuildContext`), so callers substitute
  /// `AppColors.of(context).glowFallback`, which follows the active theme.
  Future<Color?> glowColorFor(Uint8List? bytes, {String? cacheKey}) async {
    if (cacheKey != null) {
      final cached = _cache.remove(cacheKey);
      if (cached != null) {
        // Reinserting moves it to the most-recently-used end.
        return _cache[cacheKey] = cached;
      }
    }
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final color = await _dominantColor(bytes);
      if (color == null) return null;

      final glow = color.withValues(alpha: 0.35);
      if (cacheKey != null) _remember(cacheKey, glow);
      return glow;
    } catch (_) {
      return null;
    }
  }

  Future<Color?> _dominantColor(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _sampleWidth,
    );
    final frame = await codec.getNextFrame();
    try {
      final palette = await PaletteGenerator.fromImage(
        frame.image,
        maximumColorCount: 8,
      );
      return palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;
    } finally {
      frame.image.dispose();
      codec.dispose();
    }
  }

  void _remember(String key, Color color) {
    _cache[key] = color;
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}
