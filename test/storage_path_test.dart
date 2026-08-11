import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/utils/storage_path.dart';

void main() {
  test('leaves real filesystem paths untouched', () {
    expect(
      resolvePickedDirectoryPath('/storage/emulated/0/Music'),
      '/storage/emulated/0/Music',
    );
    expect(resolvePickedDirectoryPath('/Users/me/Music'), '/Users/me/Music');
  });

  test('converts a primary-volume SAF tree URI to a path', () {
    expect(
      resolvePickedDirectoryPath(
        'content://com.android.externalstorage.documents/tree/primary%3AMusic%2FRock',
      ),
      '/storage/emulated/0/Music/Rock',
    );
  });

  test('converts the storage root (empty relative path)', () {
    expect(
      resolvePickedDirectoryPath(
        'content://com.android.externalstorage.documents/tree/primary%3A',
      ),
      '/storage/emulated/0',
    );
  });

  test('converts a removable SD-card volume', () {
    expect(
      resolvePickedDirectoryPath(
        'content://com.android.externalstorage.documents/tree/1A2B-3C4D%3AMusic',
      ),
      '/storage/1A2B-3C4D/Music',
    );
  });

  test('strips a trailing /document/ segment', () {
    expect(
      resolvePickedDirectoryPath(
        'content://com.android.externalstorage.documents/tree/primary%3AMusic/document/primary%3AMusic%2FRock',
      ),
      '/storage/emulated/0/Music',
    );
  });

  test('returns unconvertible content URIs unchanged', () {
    const opaque =
        'content://com.android.providers.downloads.documents/tree/downloads';
    expect(resolvePickedDirectoryPath(opaque), opaque);
  });
}
