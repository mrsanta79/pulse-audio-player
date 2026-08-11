import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

// Re-exported so anything holding the database also has its query extensions
// (and the `Track` / `Playlist` row types) in scope from this one import.
export '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
