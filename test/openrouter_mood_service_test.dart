import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pulse_audio_player/data/database/app_database.dart';
import 'package:pulse_audio_player/data/services/openrouter_mood_service.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'uses the current model by default and persists model changes',
    () async {
      final service = OpenRouterMoodService(db, apiKeyStore: _MemoryKeyStore());
      expect(await service.getModel(), defaultMoodModel);
      await service.setModel('provider/new-model');
      expect(await service.getModel(), 'provider/new-model');
      service.close();
    },
  );

  test(
    'categorizes metadata in batches, saves valid assignments, and skips unchanged songs',
    () async {
      for (var i = 0; i < 12; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                filePath: '/music/$i.mp3',
                title: 'Song $i',
              ),
            );
      }
      final store = _MemoryKeyStore('test-key');
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.host, 'openrouter.ai');
        expect(request.headers['authorization'], 'Bearer test-key');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(
          payload['model'],
          requests <= 2 ? defaultMoodModel : 'provider/another-model',
        );
        final songs =
            jsonDecode(
                  ((payload['messages'] as List).last as Map)['content']
                      as String,
                )
                as List<dynamic>;
        expect(
          songs.every((song) => !(song as Map).containsKey('file_path')),
          isTrue,
        );
        expect(payload.containsKey('response_format'), isFalse);
        final response = {
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'songs': [
                    for (final song in songs)
                      {
                        'id': (song as Map)['id'],
                        'moods': ['happy', 'cheerful'],
                      },
                  ],
                }),
              },
            },
          ],
        };
        return http.Response(jsonEncode(response), 200);
      });
      final service = OpenRouterMoodService(
        db,
        client: client,
        apiKeyStore: store,
      );

      final firstRun = await service.categorizePending().toList();
      expect(requests, 2);
      expect(firstRun.last.done, isTrue);
      expect(firstRun.first.total, 12);
      expect(firstRun.last.completed, 12);
      expect(await db.getMoodCounts(), [
        const MoodCount('cheerful', 12),
        const MoodCount('happy', 12),
      ]);

      await service.categorizePending().toList();
      expect(requests, 2);

      await service.setModel('provider/another-model');
      await service.categorizePending().toList();
      expect(requests, 4);
      expect((await db.getMoodCounts()).length, 2);
      service.close();
    },
  );

  test('parses a model response without a usage of JSON mode', () async {
    final trackId = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            filePath: '/music/raw.mp3',
            title: 'Plain JSON',
          ),
        );
    final service = OpenRouterMoodService(
      db,
      apiKeyStore: _MemoryKeyStore('test-key'),
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'songs': [
                      {
                        'id': trackId,
                        'moods': ['happy'],
                      },
                    ],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    expect((await service.categorizePending().toList()).last.done, isTrue);
    expect(await db.watchTracksByMood('happy').first, hasLength(1));
    service.close();
  });

  test('parses fenced JSON and maps displayed mood names to ids', () async {
    final trackId = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            filePath: '/music/love.mp3',
            title: 'Love song',
          ),
        );
    final service = OpenRouterMoodService(
      db,
      apiKeyStore: _MemoryKeyStore('test-key'),
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content':
                      '```json\n{"songs":[{"id":$trackId,"moods":["Love","Road Trips"]}]}\n```',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final progress = await service.categorizePending().toList();
    expect(progress.last.done, isTrue);
    expect(await db.watchTracksByMood('love').first, hasLength(1));
    expect(await db.watchTracksByMood('road_trips').first, hasLength(1));
    service.close();
  });

  test('reports OpenRouter error payloads when choices are absent', () async {
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            filePath: '/music/rejected.mp3',
            title: 'Rejected',
          ),
        );
    final service = OpenRouterMoodService(
      db,
      apiKeyStore: _MemoryKeyStore('test-key'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'model unavailable'},
          }),
          200,
        ),
      ),
    );

    await expectLater(
      service.categorizePending().toList(),
      throwsA(
        isA<OpenRouterException>().having(
          (error) => error.message,
          'message',
          contains('model unavailable'),
        ),
      ),
    );
    service.close();
  });

  test('skips empty libraries even without an API key', () async {
    final service = OpenRouterMoodService(db, apiKeyStore: _MemoryKeyStore());
    final progress = await service.categorizePending().toList();
    expect(progress.single.done, isTrue);
    expect(progress.single.skipped, isFalse);
    service.close();
  });

  test(
    'keeps saved assignments when the server fails and skips without a key',
    () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: '/music/no-key.mp3',
              title: 'No key',
            ),
          );
      final store = _MemoryKeyStore();
      final service = OpenRouterMoodService(db, apiKeyStore: store);
      final skipped = await service.categorizePending().toList();
      expect(skipped.single.skipped, isTrue);
      service.close();

      final trackId = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: '/music/existing.mp3',
              title: 'Existing',
            ),
          );
      await db.saveTrackMoods(trackId, 'old-fingerprint', ['sad']);
      final failing = OpenRouterMoodService(
        db,
        apiKeyStore: _MemoryKeyStore('test-key'),
        client: MockClient((_) async => http.Response('rate limited', 429)),
      );
      await expectLater(
        failing.categorizePending().toList(),
        throwsA(isA<OpenRouterException>()),
      );
      expect(await db.getMoodCounts(), [const MoodCount('sad', 1)]);
      expect(await db.getTrackMoodHashes(), {trackId: 'old-fingerprint'});
      failing.close();
    },
  );
}

class _MemoryKeyStore implements MoodApiKeyStore {
  _MemoryKeyStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> delete() async => value = null;
}
