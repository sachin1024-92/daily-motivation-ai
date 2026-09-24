import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';

class Reel {
  final String id;
  final String authorId;
  final String caption;
  final String audio;
  final MediaArt art;
  final int likes;
  final bool liked;
  final bool saved;
  final int shares;
  final int views;
  final List<Comment> comments;

  const Reel({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.audio,
    required this.art,
    this.likes = 0,
    this.liked = false,
    this.saved = false,
    this.shares = 0,
    this.views = 0,
    this.comments = const [],
  });

  Reel copyWith({int? likes, bool? liked, bool? saved, int? shares, int? views, List<Comment>? comments}) {
    return Reel(
      id: id,
      authorId: authorId,
      caption: caption,
      audio: audio,
      art: art,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      comments: comments ?? this.comments,
    );
  }
}
