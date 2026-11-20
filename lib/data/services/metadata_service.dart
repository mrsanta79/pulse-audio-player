import 'dart:typed_data';

import 'package:media_metadata/media_metadata.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class TrackMetadata {
  final String title;
  final String artist;
  final String album;
  final int? year;
  final int? durationMs;
  final int? trackNumber;
  final Uint8List? albumArt;

  const TrackMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.year,
    this.durationMs,
    this.trackNumber,
    this.albumArt,
  });
}

class MetadataService {
  static const unknownArtist = 'Unknown Artist';
  static const unknownAlbum = 'Unknown Album';

  Future<TrackMetadata> read(String filePath) async {
    final fileName = p.basenameWithoutExtension(filePath);
    try {
      final metadata = await MediaMetadata.read(filePath);
      if (metadata == null) {
        return TrackMetadata(
          title: fileName,
          artist: unknownArtist,
          album: unknownAlbum,
        );
      }
      final picture = metadata.imageMetadata;

      String valueOr(String? value, String fallback) {
        final trimmed = value?.trim();
        return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
      }

      return TrackMetadata(
        title: valueOr(metadata.title, fileName),
        artist: valueOr(
          metadata.artist,
          valueOr(metadata.albumArtist, unknownArtist),
        ),
        album: valueOr(metadata.album, unknownAlbum),
        year: metadata.year,
        durationMs: metadata.duration?.inMilliseconds,
        trackNumber: metadata.trackNumber,
        albumArt: picture?.data,
      );
    } catch (_) {
      return TrackMetadata(
        title: fileName,
        artist: unknownArtist,
        album: unknownAlbum,
      );
    }
  }

  String? hashAlbumArt(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return sha1.convert(bytes).toString();
  }
}
