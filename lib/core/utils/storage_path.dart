/// Converts a directory location returned by the platform folder picker into a
/// real filesystem path that `dart:io` can read.
///
/// On Android, `FilePicker.getDirectoryPath()` returns a Storage Access
/// Framework *tree URI* such as
/// `content://com.android.externalstorage.documents/tree/primary%3AMusic%2FRock`
/// rather than a path. `dart:io`'s `Directory`/`File` cannot read `content://`
/// URIs, so we translate the URI back into the equivalent path, e.g.
/// `/storage/emulated/0/Music/Rock`.
///
/// On desktop/iOS the picker already returns a real path, which is returned
/// unchanged. Anything we can't confidently translate is returned unchanged so
/// the caller can surface the failure rather than silently corrupting the path.
String resolvePickedDirectoryPath(String picked) {
  if (!picked.startsWith('content://')) return picked;

  const treeMarker = '/tree/';
  final treeIndex = picked.indexOf(treeMarker);
  if (treeIndex == -1) return picked;

  var raw = picked.substring(treeIndex + treeMarker.length);

  // Some pickers append a `/document/<id>` segment after the tree id.
  final docIndex = raw.indexOf('/document/');
  if (docIndex != -1) raw = raw.substring(0, docIndex);

  final String documentId;
  try {
    documentId = Uri.decodeComponent(raw);
  } catch (_) {
    return picked;
  }

  // documentId looks like "primary:Music/Rock" or "1A2B-3C4D:Music".
  final colon = documentId.indexOf(':');
  if (colon == -1) return picked;

  final volume = documentId.substring(0, colon);
  final relative = documentId.substring(colon + 1);

  // Only external-storage volumes map cleanly to a filesystem path. Providers
  // like Downloads use opaque ids we can't translate.
  final base = volume == 'primary' ? '/storage/emulated/0' : '/storage/$volume';
  return relative.isEmpty ? base : '$base/$relative';
}
