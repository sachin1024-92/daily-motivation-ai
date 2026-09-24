import 'package:daily_motivation_ai/models/media_art.dart';

class StoryFrame {
  final String id;
  final MediaArt art;
  final String caption;
  final DateTime at;

  const StoryFrame({required this.id, required this.art, required this.caption, required this.at});
}

class StoryGroup {
  final String userId;
  final List<StoryFrame> frames;
  final bool seen;

  const StoryGroup({required this.userId, required this.frames, this.seen = false});

  StoryGroup copyWith({List<StoryFrame>? frames, bool? seen}) =>
      StoryGroup(userId: userId, frames: frames ?? this.frames, seen: seen ?? this.seen);
}
