import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/widgets/spinning_disc_art.dart';

/// The disc keeps its angle across a pause so resuming looks continuous. But a
/// track played from the beginning has to start its first revolution at the top,
/// rather than picking up wherever the previous song left the disc.
void main() {
  /// The disc's current rotation, read back off the transform it paints with.
  double angleOf(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(SpinningDiscArt),
        matching: find.byType(Transform),
      ),
    );
    final matrix = transform.transform.storage;
    return math.atan2(matrix[1], matrix[0]);
  }

  Future<void> pumpDisc(
    WidgetTester tester, {
    required Object trackKey,
    required Duration position,
    bool playing = true,
    Duration advance = Duration.zero,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              child: SpinningDiscArt(
                artHash: null,
                spinning: playing,
                trackKey: trackKey,
                position: position,
              ),
            ),
          ),
        ),
      ),
      duration: advance == Duration.zero ? null : advance,
    );
  }

  /// Plays [trackKey] from the top for long enough that the disc has visibly
  /// turned, and returns where it got to.
  Future<double> spinUp(WidgetTester tester, {Object trackKey = 'a'}) async {
    var position = Duration.zero;
    await pumpDisc(tester, trackKey: trackKey, position: position);
    for (var i = 0; i < 20; i++) {
      position += const Duration(milliseconds: 100);
      await pumpDisc(
        tester,
        trackKey: trackKey,
        position: position,
        advance: const Duration(milliseconds: 100),
      );
    }
    final angle = angleOf(tester);
    expect(angle, greaterThan(0.1), reason: 'disc should have turned by now');
    return angle;
  }

  testWidgets('a new track starts the disc from the top', (tester) async {
    await spinUp(tester);

    await pumpDisc(tester, trackKey: 'b', position: Duration.zero);

    expect(angleOf(tester), 0);
  });

  testWidgets('a stale position after a track change still restarts it', (
    tester,
  ) async {
    await spinUp(tester);

    // The first frame of a new track can still carry the outgoing track's
    // position; the disc keeps turning until the position actually rewinds.
    await pumpDisc(tester, trackKey: 'b', position: const Duration(seconds: 2));
    expect(angleOf(tester), isNot(0));

    await pumpDisc(tester, trackKey: 'b', position: Duration.zero);
    expect(angleOf(tester), 0);
  });

  testWidgets('resuming part-way through keeps the disc where it stopped', (
    tester,
  ) async {
    await spinUp(tester);

    // Pause, and let the disc coast to a stop.
    await pumpDisc(
      tester,
      trackKey: 'a',
      position: const Duration(seconds: 2),
      playing: false,
      advance: const Duration(seconds: 5),
    );
    final paused = angleOf(tester);
    expect(paused, isNot(0));

    await pumpDisc(
      tester,
      trackKey: 'a',
      position: const Duration(seconds: 2),
      playing: false,
    );
    expect(angleOf(tester), paused);

    await pumpDisc(tester, trackKey: 'a', position: const Duration(seconds: 2));
    expect(
      angleOf(tester),
      paused,
      reason: 'a resume must not rewind the disc',
    );
  });

  testWidgets('replaying the same track from the start restarts the disc', (
    tester,
  ) async {
    await spinUp(tester);

    // Repeat-one, or a seek back to the beginning: same track, position rewound.
    await pumpDisc(tester, trackKey: 'a', position: Duration.zero);

    expect(angleOf(tester), 0);
  });
}
