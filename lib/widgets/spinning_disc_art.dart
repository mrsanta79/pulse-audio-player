import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';
import 'album_art_with_glow.dart';
import 'disc/disc_painters.dart';
import 'disc/disc_spin.dart';

/// Album art rendered as a disc that spins while the track plays.
///
/// The disc keeps its angle when playback pauses and eases back up to speed on
/// resume (like a real player spinning down/up) rather than snapping to a stop.
/// A track that starts from the beginning does start the disc from the top,
/// though; see [_SpinningDiscArtState._syncPlayhead]. The ticker is torn down
/// once the disc has come to rest so a paused screen costs nothing per frame.
///
/// Everything that turns lives under one [RepaintBoundary] so the rotation is a
/// transform of a cached raster: no repainting of the artwork, grooves or glow
/// per frame. The glow and the sheen sit outside the rotation both because a
/// blur and a reflection shouldn't turn with the disc, and because keeping the
/// blur out of the cached layer keeps that layer small.
class SpinningDiscArt extends StatefulWidget {
  const SpinningDiscArt({
    super.key,
    required this.artHash,
    required this.spinning,
    this.trackKey,
    this.position,
    this.heroTag,
    this.revolution = const Duration(seconds: 9),
  });

  final String? artHash;

  /// Whether the disc should be turning (i.e. the player is playing).
  final bool spinning;

  /// Identifies the track on the disc. Changing it (or rewinding [position] to
  /// the start of the same track) puts the disc back at the top.
  final Object? trackKey;

  /// Current playback position, used to tell a fresh start from a resume. When
  /// null, only a change of [trackKey] restarts the disc.
  final Duration? position;

  final Object? heroTag;

  /// Time for one full revolution at full speed.
  final Duration revolution;

  @override
  State<SpinningDiscArt> createState() => _SpinningDiscArtState();
}

class _SpinningDiscArtState extends State<SpinningDiscArt>
    with SingleTickerProviderStateMixin {
  /// How near the start of a track counts as "playing it from the top".
  static const _restartWindow = Duration(seconds: 2);

  final _spin = ValueNotifier<DiscSpin>(DiscSpin.stopped);

  late final Ticker _ticker = createTicker(_onTick);
  late DiscSpinPhysics _physics = DiscSpinPhysics(
    revolution: widget.revolution,
  );
  Duration _lastTick = Duration.zero;

  Object? _lastTrackKey;
  Duration? _lastPosition;

  @override
  void initState() {
    super.initState();
    // Seed, don't restart: the disc already starts at angle 0, and opening this
    // screen mid-song shouldn't count as a fresh start.
    _lastTrackKey = widget.trackKey;
    _lastPosition = widget.position;
  }

  @override
  void didUpdateWidget(SpinningDiscArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revolution != oldWidget.revolution) {
      _physics = DiscSpinPhysics(revolution: widget.revolution);
    }
    _syncPlayhead();
    if (widget.spinning != oldWidget.spinning) _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// Sends the disc back to the top when a track (re)starts from the beginning,
  /// so a new song visibly begins its first revolution at zero. Resuming after
  /// a pause, or picking up a restored session part-way in, keeps the angle the
  /// disc had. Only playback that actually rewound resets it.
  void _syncPlayhead() {
    final position = widget.position;
    final previous = _lastPosition;
    final trackChanged = widget.trackKey != _lastTrackKey;
    _lastTrackKey = widget.trackKey;
    _lastPosition = position;

    if (position == null) {
      if (trackChanged) _resetAngle();
      return;
    }
    // The first frame after a track change can still report the outgoing
    // track's position, so a rewind counts as a restart too, which also covers
    // repeat-one looping and seeking back to the beginning.
    final rewound = previous == null || position < previous;
    if (position < _restartWindow && (trackChanged || rewound)) _resetAngle();
  }

  void _resetAngle() {
    if (_spin.value.angle == 0) return;
    _spin.value = DiscSpin(angle: 0, speed: _spin.value.speed);
  }

  /// Runs the ticker whenever the disc is turning or still slowing down. With
  /// animations disabled (accessibility setting) the disc stays put.
  void _syncTicker() {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    final shouldRun = !motionOff && (widget.spinning || _spin.value.speed > 0);

    if (shouldRun && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
      if (motionOff) _spin.value = DiscSpin(angle: _spin.value.angle, speed: 0);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    if (dt <= 0) return;

    final next = _physics.advance(_spin.value, dt, spinning: widget.spinning);
    _spin.value = next;

    if (!widget.spinning && next.speed == 0) _ticker.stop();
  }

  _DiscFace? _face;

  /// Hands back the *same* [_DiscFace] instance while nothing it draws from has
  /// changed. The screen above rebuilds on every position tick, and Flutter
  /// skips an identical child widget outright instead of re-diffing it, so this
  /// keeps the artwork decode and the groove painting off the per-frame path.
  _DiscFace _discFace(double side, Color background) {
    final cached = _face;
    if (cached != null &&
        cached.side == side &&
        cached.background == background &&
        cached.artHash == widget.artHash &&
        cached.heroTag == widget.heroTag) {
      return cached;
    }
    return _face = _DiscFace(
      side: side,
      background: background,
      artHash: widget.artHash,
      heroTag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            _DiscGlow(artHash: widget.artHash),
            RepaintBoundary(
              child: ValueListenableBuilder<DiscSpin>(
                valueListenable: _spin,
                child: _discFace(
                  constraints.biggest.shortestSide,
                  AppColors.of(context).background,
                ),
                builder: (context, spin, child) {
                  // One transform, not a scale layer wrapping a rotate layer.
                  final scale = 0.97 + 0.03 * spin.speed;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(scale, scale, 1, 1)
                      ..rotateZ(spin.angle),
                    child: child,
                  );
                },
              ),
            ),
            const CustomPaint(painter: DiscSheenPainter()),
          ],
        ),
      ),
    );
  }
}

/// The artwork with the record's face over it: everything that rotates.
///
/// A separate widget so Flutter's own element diffing skips it when nothing it
/// depends on changed. The screen above rebuilds on every position tick, and
/// this subtree depends only on the artwork, its drawn size and the theme, so
/// those rebuilds must not reach the image decode or the grooves.
class _DiscFace extends StatelessWidget {
  const _DiscFace({
    required this.side,
    required this.background,
    required this.artHash,
    required this.heroTag,
  });

  final double side;

  /// The spindle hole is painted in this, so it is part of what the face
  /// depends on: without it a theme switch would leave a stale-coloured hole.
  final Color background;
  final String? artHash;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AlbumArtWithGlow(
            artHash: artHash,
            // Decode the artwork at the size it is actually drawn at. Left to
            // itself AlbumArtWithGlow decodes for a 1080pt-wide layout, and
            // resampling a texture that large every frame is what makes the
            // spin stutter.
            size: side.isFinite ? side : null,
            // Effectively circular: RRect clamps oversized radii.
            borderRadius: 9999,
            showGlow: false,
            heroTag: heroTag,
          ),
          CustomPaint(painter: DiscFacePainter(background)),
        ],
      ),
    );
  }
}

/// The artwork-tinted halo behind the disc. Static: a blur this wide costs real
/// time to paint, so it must not be inside the rotating layer.
class _DiscGlow extends ConsumerWidget {
  const _DiscGlow({required this.artHash});

  final String? artHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final color =
        ref.watch(glowColorProvider(artHash)).valueOrNull ??
        palette.glowFallback;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 48, spreadRadius: 2)],
        ),
      ),
    );
  }
}
