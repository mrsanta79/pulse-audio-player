import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/utils/format.dart';

void main() {
  test('formatDuration pads seconds', () {
    expect(formatDuration(const Duration(seconds: 64)), '1:04');
    expect(formatDuration(Duration.zero), '0:00');
  });

  test('trackNumberLabel pads numbers', () {
    expect(trackNumberLabel(3, 0), '03');
    expect(trackNumberLabel(null, 4), '05');
  });
}
