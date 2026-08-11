import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
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
      final tag = await AudioTags.read(filePath);
      if (tag == null) {
        return TrackMetadata(
          title: fileName,
          artist: unknownArtist,
          album: unknownAlbum,
        );
      }

      final pictures = tag.pictures;
      Uint8List? art;
      if (pictures.isNotEmpty) {
        art = Uint8List.fromList(pictures.first.bytes);
      }

      final title = (tag.title?.trim().isNotEmpty ?? false)
          ? tag.title!.trim()
          : fileName;
      final artist = (tag.trackArtist?.trim().isNotEmpty ?? false)
          ? tag.trackArtist!.trim()
          : ((tag.albumArtist?.trim().isNotEmpty ?? false)
                ? tag.albumArtist!.trim()
                : unknownArtist);
      final album = (tag.album?.trim().isNotEmpty ?? false)
          ? tag.album!.trim()
          : unknownAlbum;

      return TrackMetadata(
        title: title,
        artist: artist,
        album: album,
        year: tag.year,
        durationMs: tag.duration != null ? tag.duration! * 1000 : null,
        trackNumber: tag.trackNumber,
        albumArt: art,
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
