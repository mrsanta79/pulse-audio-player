import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/folder_scanner_service.dart';
import '../services/metadata_service.dart';
import '../services/openrouter_mood_service.dart';
import '../services/palette_service.dart';
import 'database_provider.dart';

final metadataServiceProvider = Provider((ref) => MetadataService());

final paletteServiceProvider = Provider((ref) => PaletteService());

final moodCategorizationServiceProvider = Provider((ref) {
  final service = OpenRouterMoodService(ref.watch(databaseProvider));
  ref.onDispose(service.close);
  return service;
});

final scannerServiceProvider = Provider((ref) {
  return FolderScannerService(
    ref.watch(databaseProvider),
    ref.watch(metadataServiceProvider),
    ref.watch(moodCategorizationServiceProvider),
  );
});
