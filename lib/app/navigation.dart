import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/chats/chat_screen.dart';
import 'package:daily_motivation_ai/screens/create/composer_screen.dart';
import 'package:daily_motivation_ai/screens/feed/post_card.dart';
import 'package:daily_motivation_ai/screens/profile/profile_screen.dart';
import 'package:daily_motivation_ai/screens/reels/reels_screen.dart';
import 'package:daily_motivation_ai/screens/stories/story_viewer.dart';
import 'package:daily_motivation_ai/screens/watch/video_screen.dart';

// One place that knows how to open any surface of Orbit, so content can flow
// freely between the feed, reels, video, stories and chats.

Future<T?> _push<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));
}

void openProfile(BuildContext context, String userId) => _push(context, ProfileScreen(userId: userId));

void openChat(BuildContext context, String chatId) => _push(context, ChatScreen(chatId: chatId));

void openDirectChat(BuildContext context, WidgetRef ref, String userId) {
  final user = ref.read(userProvider(userId));
  final chatId = ref.read(chatsProvider.notifier).ensureDirectChat(userId, title: user.name);
  openChat(context, chatId);
}

void openPost(BuildContext context, String postId) => _push(context, PostDetailScreen(postId: postId));

void openVideo(BuildContext context, String videoId) => _push(context, VideoScreen(videoId: videoId));

void openReel(BuildContext context, String reelId) =>
    _push(context, ReelsScreen(initialReelId: reelId, standalone: true));

void openStories(BuildContext context, List<String> userIds, {int initialIndex = 0}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => StoryViewer(userIds: userIds, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(animation), child: child),
      ),
    ),
  );
}

Future<void> openComposer(BuildContext context, {Set<PublishTarget>? targets, String? initialText}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ComposerScreen(initialTargets: targets, initialText: initialText),
    ),
  );
}

/// Opens whatever was shared into a chat.
void openSharedRef(BuildContext context, WidgetRef ref, SharedRef item) {
  switch (item.kind) {
    case SharedKind.post:
      openPost(context, item.id);
    case SharedKind.reel:
      openReel(context, item.id);
    case SharedKind.video:
      openVideo(context, item.id);
    case SharedKind.story:
      final group = ref.read(storiesProvider.notifier).groupFor(item.ownerId);
      if (group != null) {
        openStories(context, [item.ownerId]);
      } else {
        openProfile(context, item.ownerId);
      }
    case SharedKind.profile:
      openProfile(context, item.ownerId);
  }
}
