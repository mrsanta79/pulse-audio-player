import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/theme/app_palette.dart';
import 'package:pulse_audio_player/data/database/app_database.dart';
import 'package:pulse_audio_player/data/repositories/theme_provider.dart';

/// Existing installs are on schema 2 and have no `preferences` table. Opening
/// the app after this change has to create it, or every theme read and write
/// throws on a table that isn't there.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pulse_migration_test');
    file = File('${dir.path}/db.sqlite');
  });

  tearDown(() async => dir.delete(recursive: true));

  /// Builds a database file that looks like it was written by the previous
  /// release: schema 2, with no preferences table.
  Future<void> writeV2Database() async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('DROP TABLE preferences');
    await db.customStatement('PRAGMA user_version = 2');
    // Some real user data, to prove the migration preserves it.
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(filePath: '/music/a.mp3', title: 'Keeper'),
        );
    await db.close();
  }

  test('upgrading from schema 2 creates the preferences table', () async {
    await writeV2Database();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // Would throw "no such table: preferences" without the migration.
    expect(await db.getPreference('theme_choice'), isNull);
    await db.setPreference('theme_choice', 'midnight');
    expect(await db.getPreference('theme_choice'), 'midnight');
  });

  test('upgrading keeps existing library data', () async {
    await writeV2Database();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final tracks = await db.getAllTracks();
    expect(tracks.map((t) => t.title), ['Keeper']);
  });

  test('an upgraded install still loads the default theme', () async {
    await writeV2Database();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // No stored preference yet, so an existing user keeps the look they had.
    final settings = await ThemeSettings.load(db);
    expect(settings.choice, AppThemeChoice.amoled);
    expect(settings.darkPalette, AppPalette.amoled);
  });

  test('a theme saved after upgrading survives the next launch', () async {
    await writeV2Database();

    final first = AppDatabase.forTesting(NativeDatabase(file));
    await first.setPreference('theme_choice', 'system');
    await first.setPreference('theme_dark_variant', 'midnight');
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(second.close);

    final settings = await ThemeSettings.load(second);
    expect(settings.choice, AppThemeChoice.system);
    expect(settings.darkVariant, AppDarkVariant.midnight);
  });
}
