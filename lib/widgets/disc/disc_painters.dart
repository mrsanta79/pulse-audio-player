import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grooves, label ring and spindle hole: everything that turns with the disc.
/// All radii are fractions of the disc radius.
///
/// The disc's own shading is deliberately theme-independent: it depicts a black
/// vinyl record, so its highlights stay white-on-black in every theme. Only
/// [background] follows the theme, because the spindle hole shows the page
/// through it.
class DiscFacePainter extends CustomPainter {
  const DiscFacePainter(this.background);

  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    _paintEdgeFalloff(canvas, center, r);
    _paintGrooves(canvas, center, r);
    _paintLabel(canvas, center, r);
    _paintSpindle(canvas, center, r);
  }

  /// Darkens towards the edge so the disc reads as a curved surface.
  void _paintEdgeFalloff(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  void _paintGrooves(Canvas canvas, Offset center, double r) {
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = math.max(0.6, r * 0.004);
    for (var f = 0.42; f < 0.98; f += 0.055) {
      canvas.drawCircle(center, r * f, groove);
    }
  }

  /// A dimmed hub with the stacking ring around it.
  void _paintLabel(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r * 0.3,
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    canvas.drawCircle(
      center,
      r * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = math.max(1, r * 0.006),
    );
    canvas.drawCircle(
      center,
      r * 0.19,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = math.max(1, r * 0.01),
    );
  }

  /// The hole, punched through to the page background.
  void _paintSpindle(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r * 0.075, Paint()..color = background);
    canvas.drawCircle(
      center,
      r * 0.075,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = math.max(1, r * 0.006),
    );
  }

  @override
  bool shouldRepaint(DiscFacePainter oldDelegate) =>
      oldDelegate.background != background;
}

/// The fixed specular highlight across the disc plus its rim light. Sits
/// outside the rotation: a reflection doesn't turn with the record.
class DiscSheenPainter extends CustomPainter {
  const DiscSheenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: r);

    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));
    _paintBands(canvas, bounds);
    _paintGlare(canvas, bounds);
    canvas.restore();

    _paintRim(canvas, center, r);
  }

  /// Two opposed bands of light, as a glossy disc catches under one source.
  void _paintBands(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: [
            Color(0x00FFFFFF),
            Color(0x1FFFFFFF),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x14FFFFFF),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.0, 0.12, 0.28, 0.45, 0.6, 0.76, 1.0],
        ).createShader(bounds),
    );
  }

  /// Diagonal glare across the top-left quadrant.
  void _paintGlare(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF)],
          stops: [0.0, 0.42, 1.0],
        ).createShader(bounds),
    );
  }

  /// A thin bright edge that fades around the disc.
  void _paintRim(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r - math.max(0.5, r * 0.005),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.01)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x59FFFFFF), Color(0x1FFFFFFF), Color(0x0DFFFFFF)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(DiscSheenPainter oldDelegate) => false;
}
