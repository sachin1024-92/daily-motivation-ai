import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/reel.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/models/video.dart';

int _uid = 0;
String newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_uid++}';

Comment _myComment(String text) => Comment(id: newId('cm'), authorId: meId, text: text.trim(), at: DateTime.now());

// ---------------------------------------------------------------------------
// Feed (Facebook / Instagram posts)
// ---------------------------------------------------------------------------

final feedProvider = StateNotifierProvider<FeedNotifier, List<Post>>((ref) => FeedNotifier());

final postProvider = Provider.family<Post?, String>((ref, id) {
  for (final p in ref.watch(feedProvider)) {
    if (p.id == id) return p;
  }
  return null;
});

class FeedNotifier extends StateNotifier<List<Post>> {
  FeedNotifier([List<Post>? initial]) : super(initial ?? seedPosts());

  void _update(String id, Post Function(Post) change) {
    state = [for (final p in state) p.id == id ? change(p) : p];
  }

  /// Sets my reaction. Reacting with the current reaction again removes it.
  void react(String postId, String? emoji) {
    _update(postId, (p) {
      final counts = Map<String, int>.of(p.reactions);
      final previous = p.myReaction;
      if (previous != null) {
        counts[previous] = (counts[previous] ?? 1) - 1;
        if (counts[previous]! <= 0) counts.remove(previous);
      }
      final next = emoji == previous ? null : emoji;
      if (next != null) counts[next] = (counts[next] ?? 0) + 1;
      return p.copyWith(reactions: counts, myReaction: next);
    });
  }

  /// Double-tap / heart button: toggles a ❤️ (or clears any reaction).
  void toggleLove(String postId) {
    final post = state.firstWhere((p) => p.id == postId);
    react(postId, post.myReaction ?? '❤️');
  }

  void vote(String postId, int option) {
    _update(postId, (p) {
      if (p.myVote != null || option < 0 || option >= p.poll.length) return p;
      final poll = [for (var i = 0; i < p.poll.length; i++) i == option ? p.poll[i].voted() : p.poll[i]];
      return p.copyWith(poll: poll, myVote: option);
    });
  }

  void addComment(String postId, String text) {
    if (text.trim().isEmpty) return;
    _update(postId, (p) => p.copyWith(comments: [...p.comments, _myComment(text)]));
  }

  void toggleSave(String postId) => _update(postId, (p) => p.copyWith(saved: !p.saved));

  void registerShare(String postId) => _update(postId, (p) => p.copyWith(shares: p.shares + 1));

  void add(Post post) => state = [post, ...state];
}

final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.forYou);

enum FeedFilter { forYou, following, saved }

// ---------------------------------------------------------------------------
// Stories (Instagram stories / WhatsApp status)
// ---------------------------------------------------------------------------

final storiesProvider = StateNotifierProvider<StoriesNotifier, List<StoryGroup>>((ref) => StoriesNotifier());

class StoriesNotifier extends StateNotifier<List<StoryGroup>> {
  StoriesNotifier() : super(seedStories());

  StoryGroup? groupFor(String userId) {
    for (final g in state) {
      if (g.userId == userId) return g;
    }
    return null;
  }

  void markSeen(String userId) {
    state = [for (final g in state) g.userId == userId && userId != meId ? g.copyWith(seen: true) : g];
  }

  /// Adds a frame to my story (my story always stays first).
  void addToMyStory(StoryFrame frame) {
    final mine = groupFor(meId);
    final updated = mine == null
        ? StoryGroup(userId: meId, frames: [frame])
        : mine.copyWith(frames: [...mine.frames, frame]);
    state = [updated, ...state.where((g) => g.userId != meId)];
  }
}

// ---------------------------------------------------------------------------
// Reels (Instagram Reels / YouTube Shorts)
// ---------------------------------------------------------------------------

final reelsProvider = StateNotifierProvider<ReelsNotifier, List<Reel>>((ref) => ReelsNotifier());

class ReelsNotifier extends StateNotifier<List<Reel>> {
  ReelsNotifier() : super(seedReels());

  void _update(String id, Reel Function(Reel) change) {
    state = [for (final r in state) r.id == id ? change(r) : r];
  }

  void toggleLike(String id) => _update(id, (r) => r.copyWith(liked: !r.liked, likes: r.likes + (r.liked ? -1 : 1)));

  /// Double-tap only ever likes, never unlikes.
  void like(String id) => _update(id, (r) => r.liked ? r : r.copyWith(liked: true, likes: r.likes + 1));

  void toggleSave(String id) => _update(id, (r) => r.copyWith(saved: !r.saved));

  void registerShare(String id) => _update(id, (r) => r.copyWith(shares: r.shares + 1));

  void registerView(String id) => _update(id, (r) => r.copyWith(views: r.views + 1));

  void addComment(String id, String text) {
    if (text.trim().isEmpty) return;
    _update(id, (r) => r.copyWith(comments: [...r.comments, _myComment(text)]));
  }

  void add(Reel reel) => state = [reel, ...state];
}

// ---------------------------------------------------------------------------
// Watch (YouTube)
// ---------------------------------------------------------------------------

final videosProvider = StateNotifierProvider<VideosNotifier, List<Video>>((ref) => VideosNotifier());

final videoProvider = Provider.family<Video?, String>((ref, id) {
  for (final v in ref.watch(videosProvider)) {
    if (v.id == id) return v;
  }
  return null;
});

final watchCategoryProvider = StateProvider<String>((ref) => videoCategories.first);

class VideosNotifier extends StateNotifier<List<Video>> {
  VideosNotifier() : super(seedVideos());

  void _update(String id, Video Function(Video) change) {
    state = [for (final v in state) v.id == id ? change(v) : v];
  }

  void toggleLike(String id) => _update(
        id,
        (v) => v.copyWith(liked: !v.liked, disliked: false, likes: v.likes + (v.liked ? -1 : 1)),
      );

  void toggleDislike(String id) => _update(
        id,
        (v) => v.copyWith(disliked: !v.disliked, liked: false, likes: v.liked ? v.likes - 1 : v.likes),
      );

  void toggleWatchLater(String id) => _update(id, (v) => v.copyWith(watchLater: !v.watchLater));

  void registerView(String id) => _update(id, (v) => v.copyWith(views: v.views + 1));

  void addComment(String id, String text) {
    if (text.trim().isEmpty) return;
    _update(id, (v) => v.copyWith(comments: [...v.comments, _myComment(text)]));
  }
}

// ---------------------------------------------------------------------------
// Activity (notifications)
// ---------------------------------------------------------------------------

final activityProvider = StateNotifierProvider<ActivityNotifier, List<ActivityItem>>((ref) => ActivityNotifier());

final unreadActivityProvider = Provider<int>((ref) => ref.watch(activityProvider).where((a) => !a.read).length);

class ActivityNotifier extends StateNotifier<List<ActivityItem>> {
  ActivityNotifier() : super(seedActivity());

  void markAllRead() {
    if (state.every((a) => a.read)) return;
    state = [for (final a in state) a.markRead()];
  }
}
