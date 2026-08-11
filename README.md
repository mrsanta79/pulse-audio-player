# Pulse

A minimal, offline Android music player built with Flutter. It scans folders you pick, reads tags straight off the files, and plays them with a media notification and background playback. No accounts, no network, no algorithm.

- **Package**: `com.pulse.audio_player`
- **Platform**: Android only (no `ios/`, `web/`, or desktop targets in this repo)
- **Minimum Android**: SDK 24 (Android 7.0)

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Building](#building)
- [Testing](#testing)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Database](#database)
- [Permissions](#permissions)
- [Troubleshooting](#troubleshooting)

---

## Features

**Library**
- Folder-based scanning: only the folders you add are imported, nothing else on the device is touched
- Tags read with `audiotags`, filename used as the title fallback
- Browse by artist, album, year, or all songs
- Album art extracted from tags, deduplicated by content hash, stored once and shared across tracks
- Rescan updates changed tags and drops tracks whose files disappeared from a scanned folder
- Supported extensions: `.mp3`, `.flac`, `.m4a`, `.ogg`, `.wav`, `.aac`, `.opus`

**Playback**
- Background playback with a media notification and hardware media-button support (`audio_service`)
- Shuffle and repeat (off / all / one)
- Queue view, reorderable playback position, skip to any queue item
- Session resume: the queue, current track, position, shuffle, and repeat mode survive an app restart
- Waveform-style scrub bar, spinning disc album art

**Gestures**
- Swipe the album art left/right for previous/next
- Double-tap the album art to play/pause
- Swipe the mini player up to expand, swipe the full player down to collapse

**Organisation**
- Likes, with a dedicated "Liked songs" list
- User playlists, with add/remove from a bottom sheet that knows which tracks are already in each playlist
- Whole-album add: only the tracks not already in the playlist get added

**Search**
- Full-library search across songs, albums, and artists, backed by the database
- In-list search on library screens, filtered in memory, matching every whitespace-separated term in any order ("cure the" finds "The Cure")

**Appearance**
- Four theme choices: AMOLED (default), Midnight, Light, Follow system
- When following the system, the preferred dark flavour (AMOLED or Midnight) is remembered separately
- Theme is read before the first frame, so there is no flash of the wrong palette
- Subtle dominant-colour glow behind album art, derived with `palette_generator`
- Portrait, landscape, and split-screen layouts

---

## Requirements

| Tool | Version |
| --- | --- |
| Flutter SDK | 3.35.6 (stable) or newer |
| Dart SDK | 3.9.2 (`environment: sdk: ^3.9.2`) |
| Android SDK | compile/target SDK come from the Flutter toolchain |
| JDK | 17 recommended (source/target compatibility is set to 11) |
| Gradle | 8.12 (via the wrapper, downloaded automatically) |
| Android Gradle Plugin | 8.9.1 |
| Kotlin | 2.1.0 |

You also need a device or emulator running Android 7.0 (API 24) or later. For anything on Android 11+, the app needs the **All files access** permission to read arbitrary folders by path (see [Permissions](#permissions)).

Verify your toolchain:

```bash
flutter doctor
```

`android/local.properties` must point at your Flutter and Android SDKs. Flutter generates it on the first build, but if the Gradle build complains with `flutter.sdk not set in local.properties`, create it:

```properties
sdk.dir=/path/to/Android/sdk
flutter.sdk=/path/to/flutter
```

---

## Getting started

```bash
git clone <repo-url> pulse-audio-player
cd pulse-audio-player

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

`build_runner` generates `lib/data/database/app_database.g.dart` from the Drift table definitions. The generated file is checked in, so this step is only strictly required after you change anything in `lib/data/database/app_database.dart`. Running it on a fresh clone is harmless.

---

## Usage

1. Launch the app. The library starts empty.
2. Open **Settings** (the gear icon on Home or Library).
3. Tap **Add folder**. Grant **All files access** when Android asks: the picker opens once the permission is granted.
4. Pick a folder containing music. The scan starts automatically and reports progress.
5. Tap **Rescan** any time after adding or changing files.

Everything else follows from there: Home shows recent albums, Library browses by artist/album/year/song, Search queries the whole library, and Hotlist holds liked songs and playlists.

To remove a folder, open **Settings** and delete it from the **Music folders** list. Tracks under that folder stay in the library until the next rescan.

---

## Building

### Debug

```bash
flutter run                     # attached to a connected device
flutter run --release           # release build on a device
flutter build apk --debug
```

### Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Split per ABI to cut the download size:

```bash
flutter build apk --release --split-per-abi
```

### App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Signing

The release build type currently signs with the **debug keystore** so `flutter build --release` works out of the box:

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

That is fine for sideloading, but a debug-signed artifact cannot be published. Before shipping, create a keystore, add a `key.properties` file, and wire a real `signingConfigs.release` into `android/app/build.gradle.kts`. The `applicationId` (`com.pulse.audio_player`) should also be changed to a domain you own.

### Other useful commands

```bash
flutter analyze                 # static analysis (flutter_lints 5, see analysis_options.yaml)
flutter clean                   # wipe build/ and .dart_tool/
dart run build_runner watch     # regenerate Drift code as you edit the schema
```

---

## Testing

```bash
flutter test                    # whole suite, 56 tests
flutter test test/theme_test.dart
flutter test --coverage
```

`test/flutter_test_config.dart` runs before every test and disables Google Fonts runtime fetching, so theme-building tests do not wait on a network request that cannot succeed in CI.

What the suite covers:

| File | Covers |
| --- | --- |
| `migration_test.dart` | Drift schema upgrades from v2 and v3, and that existing data and saved themes survive them |
| `playback_session_test.dart` | Saving, restoring, and clearing the resume point, including queues whose files have gone |
| `playlist_membership_test.dart` | The add-to-playlist sheet: per-playlist membership counts, partial album adds, and removals |
| `theme_test.dart` | Theme resolution, storage-key round trips, persistence, and the appearance settings UI |
| `library_search_test.dart` | In-list search: toggling, multi-term matching, empty results, and restoring the full list |
| `album_search_test.dart` | Album list filtering |
| `router_test.dart` | Full-screen routes resolving on the root navigator |
| `storage_path_test.dart` | SAF tree URI to filesystem path conversion |
| `spinning_disc_test.dart` | Disc rotation resets on track change and resumes mid-track |
| `widget_test.dart` | Duration and track-number formatting |

---

## Project structure

```
lib/
├── main.dart                  # bootstrap: database, theme preload, audio service, session restore
├── app.dart                   # MaterialApp.router, theme wiring, system UI overlay
├── core/
│   ├── router/                # go_router config and route path builders
│   ├── theme/                 # palettes (AMOLED / Midnight / Light) and ThemeData construction
│   └── utils/                 # duration formatting, in-memory search filter, SAF path resolution
├── data/
│   ├── database/              # Drift schema, generated code, and query extensions
│   │   └── queries/           # library, playlist, and session queries
│   ├── repositories/          # Riverpod providers (database, services, player, theme, UI state)
│   └── services/              # audio handler, folder scanner, tag reader, palette, session store
├── features/                  # one directory per screen, with its own widgets/
│   ├── album/  home/  hotlist/  library/  now_playing/  search/  settings/  shell/
└── widgets/                   # shared widgets: mini player, expanded player, tiles, disc, sheets

test/                          # unit and widget tests
android/                       # Android host project, manifest, Gradle config
```

---

## Architecture

**State**: Riverpod (`flutter_riverpod`). The database, audio handler, and initial theme settings are constructed in `main()` and injected into `ProviderScope` as overrides, which is what makes them straightforward to fake in tests.

**Routing**: `go_router`. Four bottom-nav tabs live inside a `StatefulShellRoute.indexedStack`, each keeping its own navigation stack, wrapped in a `PlayerOverlay` that draws the mini player and nav bar. Full-screen routes (settings, album, artist, year, playlist, likes) are siblings of the shell route on the root navigator, so they render above the overlay. `/now-playing` is kept as a redirect for the old route shape: the player is an overlay now, not a route.

**Audio**: `just_audio` for decoding, `audio_service` for the media session, notification, and lock-screen controls, `audio_session` for focus handling. `AppAudioHandler` owns the queue and exposes a combined `PlayerStateSnapshot` stream that the UI providers slice into narrow, individually watchable pieces so a position tick does not rebuild the whole screen.

**Startup order** (`lib/main.dart`):
1. Open the database
2. Load theme preferences and set the system overlay style, before the first frame
3. Initialise the audio service (a failure here shows an error screen instead of a broken app)
4. `runApp`
5. Restore the last playback session after the first frame, so startup is not blocked on reading the queue

**Scanning**: `FolderScannerService` walks each folder recursively, reads tags per file, and writes in transactions of 50 tracks. Batching is deliberate: one transaction per file spends most of its time in `fsync`, while one transaction for the whole library would lose everything if the scan were interrupted. Existing paths are fetched in a single query rather than one round trip per file. It emits a `ScanProgress` stream that the settings screen renders as a progress bar.

---

## Database

Drift over SQLite, stored at `<app documents>/pulse_music.sqlite`. Current schema version: **4**.

| Table | Purpose |
| --- | --- |
| `tracks` | One row per audio file: path (unique), title, artist, album, year, duration, track number, art hash |
| `album_art` | Artwork blobs keyed by content hash, so an album's cover is stored once |
| `scan_folders` | The folders the user chose to import from |
| `likes` | Liked track ids, cascading on track delete |
| `playlists` / `playlist_tracks` | User playlists and their ordered members, both cascading |
| `playback_sessions` | Single row (id 0) holding the resume point: queue, index, position, repeat, shuffle |
| `preferences` | Generic key/value store for small settings, so a new preference needs no schema bump |

Indexes cover the browse and sort paths: `(album, artist)`, `artist`, `year`, `title` on tracks, `liked_at` on likes, and `(playlist_id, position)` plus `track_id` on playlist entries.

Migrations are additive: v2 added `playback_sessions`, v3 added `preferences`, v4 created the indexes. Index creation is re-runnable (`CREATE INDEX IF NOT EXISTS`), so a half-finished upgrade cannot leave the app unable to open its database. `PRAGMA foreign_keys = ON` is set on every connection in `beforeOpen`, since SQLite ignores the declared cascades without it.

After editing the schema, bump `schemaVersion`, add the migration step, and regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Why |
| --- | --- |
| `MANAGE_EXTERNAL_STORAGE` | Reading user-chosen folders by filesystem path on Android 11+ |
| `READ_MEDIA_AUDIO` | Scoped audio access on Android 13+ |
| `READ_EXTERNAL_STORAGE` (max SDK 32) | Storage access on older releases |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Playing while the app is backgrounded |
| `WAKE_LOCK` | Keeping playback alive with the screen off |
| `INTERNET` | Google Fonts fetching the Inter typeface on first run |

The settings screen asks for **All files access** first and falls back to the scoped audio/storage permissions on older versions. The request opens a system settings page, so the app rechecks the grant when the user comes back. Folder picking is blocked until access is granted, because scanning without it silently finds nothing, which reads as "the app cannot see my music" rather than "grant this permission".

`MANAGE_EXTERNAL_STORAGE` requires a declared justification for Play Store distribution. A media player reading a user-selected library is an accepted use, but the listing has to say so.

---

## Troubleshooting

**"Add folder" does nothing, or the scan finds zero files**
All files access was not granted. Open Android Settings, find Pulse under "All files access" or "Special app access", enable it, then add the folder again.

**Folder was added but tracks are missing**
Only the extensions listed under [Features](#features) are imported. Symlinks are not followed. Try **Rescan** from settings.

**`flutter.sdk not set in local.properties`**
Create `android/local.properties` with `sdk.dir` and `flutter.sdk` as shown in [Requirements](#requirements).

**Build fails after changing the Drift schema**
Regenerate the code: `dart run build_runner build --delete-conflicting-outputs`.

**"Failed to start audio engine. Please restart the app."**
`audio_service` could not initialise, usually because the `AudioService` declaration in the manifest was changed or the previous instance is still shutting down. Force-stop the app and relaunch.

**Tests hang or fail on fonts**
Make sure `test/flutter_test_config.dart` is present. Flutter picks it up automatically for everything under `test/`.

---

## Stack

`flutter_riverpod` · `go_router` · `drift` + `sqlite3_flutter_libs` · `just_audio` · `audio_service` · `audio_session` · `audiotags` · `file_picker` · `permission_handler` · `palette_generator` · `google_fonts` · `path_provider` · `rxdart` · `intl` · `crypto` · `collection`
