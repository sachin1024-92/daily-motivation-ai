import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';

const List<String> videoCategories = ['All', 'Tech', 'Music', 'Fitness', 'Food', 'Travel', 'Mindset'];

class Video {
  final String id;
  final String channelId;
  final String title;
  final String description;
  final String category;
  final int durationSeconds;
  final int views;
  final int likes;
  final bool liked;
  final bool disliked;
  final bool watchLater;
  final DateTime uploadedAt;
  final MediaArt art;
  final List<Comment> comments;

  const Video({
    required this.id,
    required this.channelId,
    required this.title,
    required this.description,
    required this.category,
    required this.durationSeconds,
    required this.views,
    required this.likes,
    required this.uploadedAt,
    required this.art,
    this.liked = false,
    this.disliked = false,
    this.watchLater = false,
    this.comments = const [],
  });

  Video copyWith({
    int? views,
    int? likes,
    bool? liked,
    bool? disliked,
    bool? watchLater,
    List<Comment>? comments,
  }) {
    return Video(
      id: id,
      channelId: channelId,
      title: title,
      description: description,
      category: category,
      durationSeconds: durationSeconds,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      disliked: disliked ?? this.disliked,
      watchLater: watchLater ?? this.watchLater,
      uploadedAt: uploadedAt,
      art: art,
      comments: comments ?? this.comments,
    );
  }
}
