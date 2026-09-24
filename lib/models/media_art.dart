import 'package:flutter/painting.dart';

/// Generative artwork used for posts, stories, reels and video thumbnails.
///
/// Orbit ships offline-first, so every piece of media is rendered from a
/// gradient + emoji + seed instead of a network image. When a real media
/// backend is plugged in, [MediaArt] doubles as the placeholder/blur-hash.
class MediaArt {
  final List<Color> colors;
  final String emoji;
  final int seed;

  const MediaArt({required this.colors, required this.emoji, this.seed = 0});

  MediaArt copyWith({List<Color>? colors, String? emoji, int? seed}) => MediaArt(
        colors: colors ?? this.colors,
        emoji: emoji ?? this.emoji,
        seed: seed ?? this.seed,
      );
}

/// Curated gradient "vibes" offered in the composer.
const List<List<Color>> artPalettes = [
  [Color(0xFF7C4DFF), Color(0xFFFF4081)],
  [Color(0xFFFF512F), Color(0xFFF09819)],
  [Color(0xFF00C6FF), Color(0xFF0072FF)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  [Color(0xFF0F2027), Color(0xFF2C5364)],
  [Color(0xFFF7971E), Color(0xFFFFD200)],
  [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  [Color(0xFFEE0979), Color(0xFFFF6A00)],
  [Color(0xFF00B09B), Color(0xFF96C93D)],
];

const List<String> artEmojis = ['✨', '🌅', '🏔️', '🎧', '💻', '🍜', '🏃', '🌊', '🔥', '🌸', '🚀', '📚'];
