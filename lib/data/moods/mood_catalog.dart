import 'package:flutter/material.dart';

class MoodDefinition {
  const MoodDefinition(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const moodCatalog = <MoodDefinition>[
  MoodDefinition(
    'happy',
    'Happy',
    Icons.sentiment_very_satisfied_rounded,
    Color(0xFFFFC857),
  ),
  MoodDefinition('sad', 'Sad', Icons.water_drop_rounded, Color(0xFF7195D8)),
  MoodDefinition(
    'cheerful',
    'Cheerful',
    Icons.wb_sunny_rounded,
    Color(0xFFFF8C61),
  ),
  MoodDefinition('love', 'Love', Icons.favorite_rounded, Color(0xFFE66D8A)),
  MoodDefinition(
    'road_trips',
    'Road Trips',
    Icons.directions_car_rounded,
    Color(0xFF56B9A5),
  ),
  MoodDefinition('chill', 'Chill', Icons.air_rounded, Color(0xFF74B8C5)),
  MoodDefinition('relax', 'Relax', Icons.spa_rounded, Color(0xFF9BBD78)),
  MoodDefinition(
    'vibing',
    'Vibing',
    Icons.graphic_eq_rounded,
    Color(0xFFAB86D7),
  ),
  MoodDefinition(
    'energetic',
    'Energetic',
    Icons.bolt_rounded,
    Color(0xFFE77B42),
  ),
  MoodDefinition(
    'focus',
    'Focus',
    Icons.center_focus_strong_rounded,
    Color(0xFF7480C4),
  ),
  MoodDefinition(
    'party',
    'Party',
    Icons.celebration_rounded,
    Color(0xFFD96DB0),
  ),
  MoodDefinition(
    'nostalgic',
    'Nostalgic',
    Icons.history_rounded,
    Color(0xFFB98B61),
  ),
];

MoodDefinition? moodById(String id) {
  for (final mood in moodCatalog) {
    if (mood.id == id) return mood;
  }
  return null;
}
