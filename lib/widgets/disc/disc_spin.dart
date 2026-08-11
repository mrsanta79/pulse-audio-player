import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Where the disc is and how fast it is turning.
@immutable
class DiscSpin {
  const DiscSpin({required this.angle, required this.speed});

  static const stopped = DiscSpin(angle: 0, speed: 0);

  /// Current rotation in radians.
  final double angle;

  /// 0 = stopped, 1 = full speed.
  final double speed;

  @override
  bool operator ==(Object other) =>
      other is DiscSpin && other.angle == angle && other.speed == speed;

  @override
  int get hashCode => Object.hash(angle, speed);
}

/// The disc's equation of motion, kept apart from the widget so the spin-up and
/// spin-down feel can be reasoned about (and tested) on its own.
class DiscSpinPhysics {
  const DiscSpinPhysics({required this.revolution});

  /// Seconds for the speed to close most of the gap to its target. Spin-down is
  /// slower than spin-up so the disc coasts to a stop rather than braking.
  static const spinUpTau = 0.35;
  static const spinDownTau = 0.9;

  /// Below this, the disc is treated as stopped and the ticker can be torn
  /// down; otherwise it would creep towards zero forever.
  static const _restingSpeed = 0.005;

  /// Time for one full revolution at full speed.
  final Duration revolution;

  /// Advances [from] by [dt] seconds, heading for full speed when [spinning].
  DiscSpin advance(DiscSpin from, double dt, {required bool spinning}) {
    final target = spinning ? 1.0 : 0.0;
    final tau = spinning ? spinUpTau : spinDownTau;

    var speed = from.speed + (target - from.speed) * (1 - math.exp(-dt / tau));
    if (!spinning && speed < _restingSpeed) speed = 0;

    final radiansPerSecond = 2 * math.pi / (revolution.inMilliseconds / 1000);
    final angle = (from.angle + radiansPerSecond * speed * dt) % (2 * math.pi);

    return DiscSpin(angle: angle, speed: speed);
  }
}
