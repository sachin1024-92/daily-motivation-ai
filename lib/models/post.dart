import 'package:daily_motivation_ai/models/media_art.dart';

/// Facebook-style reactions, available on posts and chat messages.
const List<String> reactionEmojis = ['❤️', '😂', '😮', '😢', '🔥', '👏'];

const _keep = Object();

class Comment {
  final String id;
  final String authorId;
  final String text;
  final DateTime at;

  const Comment({required this.id, required this.authorId, required this.text, required this.at});
}

class PollOption {
  final String label;
  final int votes;

  const PollOption(this.label, [this.votes = 0]);

  PollOption voted() => PollOption(label, votes + 1);
}

class Post {
  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final MediaArt? art;
  final String? location;
  final List<PollOption> poll;
  final int? myVote;
  final Map<String, int> reactions;
  final String? myReaction;
  final List<Comment> comments;
  final bool saved;
  final int shares;

  const Post({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.art,
    this.location,
    this.poll = const [],
    this.myVote,
    this.reactions = const {},
    this.myReaction,
    this.comments = const [],
    this.saved = false,
    this.shares = 0,
  });

  bool get hasPoll => poll.isNotEmpty;

  int get reactionTotal => reactions.values.fold(0, (a, b) => a + b);

  int get pollTotal => poll.fold(0, (a, o) => a + o.votes);

  /// Up to three most-used reactions, most popular first.
  List<String> get topReactions {
    final entries = reactions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }

  Post copyWith({
    String? text,
    List<PollOption>? poll,
    Object? myVote = _keep,
    Map<String, int>? reactions,
    Object? myReaction = _keep,
    List<Comment>? comments,
    bool? saved,
    int? shares,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      text: text ?? this.text,
      createdAt: createdAt,
      art: art,
      location: location,
      poll: poll ?? this.poll,
      myVote: identical(myVote, _keep) ? this.myVote : myVote as int?,
      reactions: reactions ?? this.reactions,
      myReaction: identical(myReaction, _keep) ? this.myReaction : myReaction as String?,
      comments: comments ?? this.comments,
      saved: saved ?? this.saved,
      shares: shares ?? this.shares,
    );
  }
}
