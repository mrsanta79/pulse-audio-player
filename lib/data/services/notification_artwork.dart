import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Supplies artwork to the system media notification.
///
/// Android reads notification art from a file, not from memory, so each cover
/// has to be spilled to the temp directory once. Only the playing track's art
/// is ever resolved: doing the whole queue up front meant a database read and a
/// file write per track, which stalled playback for seconds on a big library.
class NotificationArtwork {
  NotificationArtwork(this._loadBytes);

  final Future<Uint8List?> Function(String? hash) _loadBytes;

  /// Files already written this run, so replaying a track doesn't re-check the
  /// filesystem.
  final Map<String, Uri> _written = {};

  /// A `file://` URI for [hash], or null if there is no artwork for it (or it
  /// could not be written, which must not interrupt playback).
  Future<Uri?> uriFor(String? hash) async {
    if (hash == null) return null;

    final cached = _written[hash];
    if (cached != null) return cached;

    try {
      final bytes = await _loadBytes(hash);
      if (bytes == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/art_$hash.jpg');
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
      }
      return _written[hash] = Uri.file(file.path);
    } catch (_) {
      return null;
    }
  }
}
