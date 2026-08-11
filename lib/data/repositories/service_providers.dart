import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/folder_scanner_service.dart';
import '../services/metadata_service.dart';
import '../services/palette_service.dart';
import 'database_provider.dart';

final metadataServiceProvider = Provider((ref) => MetadataService());

final paletteServiceProvider = Provider((ref) => PaletteService());

final scannerServiceProvider = Provider((ref) {
  return FolderScannerService(
    ref.watch(databaseProvider),
    ref.watch(metadataServiceProvider),
  );
});
