String formatDuration(Duration d) {
  final totalSeconds = d.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatDurationMs(int? ms) {
  if (ms == null || ms <= 0) return '0:00';
  return formatDuration(Duration(milliseconds: ms));
}

String trackNumberLabel(int? number, int index) {
  final n = number ?? (index + 1);
  return n.toString().padLeft(2, '0');
}
