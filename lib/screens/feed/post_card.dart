import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/services/external_share.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';
import 'package:daily_motivation_ai/widgets/sheets.dart';

const _reactionLabels = {'❤️': 'Love', '😂': 'Haha', '😮': 'Wow', '😢': 'Sad', '🔥': 'Fire', '👏': 'Clap'};

/// A feed post: Facebook-style reactions + Instagram-style media, with
/// polls, comments and share-to-anywhere.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    if (post == null) return const SizedBox.shrink();
    final author = ref.watch(userProvider(post.authorId));
    final story = ref.watch(storiesProvider.select((groups) {
      for (final g in groups) {
        if (g.userId == post.authorId) return g.seen ? StoryRing.seen : StoryRing.unseen;
      }
      return StoryRing.none;
    }));
    final feed = ref.read(feedProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final shareRef = SharedRef(
      kind: SharedKind.post,
      id: post.id,
      ownerId: post.authorId,
      title: post.text,
      art: post.art,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => story == StoryRing.none
                        ? openProfile(context, author.id)
                        : openStories(context, [author.id]),
                    child: OrbitAvatar(user: author, size: 42, ring: story),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openProfile(context, author.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserName(user: author),
                          Text(
                            ['@${author.handle}', timeAgo(post.createdAt), if (post.location != null) post.location!]
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) {
                      switch (value) {
                        case 'save':
                          feed.toggleSave(post.id);
                        case 'external':
                          ExternalShare.share(context, '${post.text}\n\n— @${author.handle} on Orbit ✨');
                        case 'message':
                          openDirectChat(context, ref, author.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'save', child: Text(post.saved ? 'Remove from saved' : 'Save post')),
                      const PopupMenuItem(value: 'external', child: Text('Share to other apps')),
                      if (author.id != meId)
                        PopupMenuItem(value: 'message', child: Text('Message ${author.name.split(' ').first}')),
                    ],
                  ),
                ],
              ),
            ),
            if (post.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(post.text, style: const TextStyle(fontSize: 15, height: 1.35)),
              ),
            if (post.art != null)
              DoubleTapLike(
                onDoubleTap: () {
                  if (post.myReaction == null) feed.react(post.id, '❤️');
                },
                child: AspectRatio(aspectRatio: 1, child: ArtCanvas(art: post.art!, emojiSize: 96)),
              ),
            if (post.hasPoll) PollView(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  if (post.reactionTotal > 0) ...[
                    Text(post.topReactions.join(), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(compactCount(post.reactionTotal), style: TextStyle(color: muted, fontSize: 13)),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${compactCount(post.comments.length)} comments · ${compactCount(post.shares)} shares',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: _PostAction(
                      key: ValueKey('react-${post.id}'),
                      icon: post.myReaction == null
                          ? const Icon(Icons.favorite_border_rounded, size: 21)
                          : Text(post.myReaction!, style: const TextStyle(fontSize: 18)),
                      label: post.myReaction == null ? 'Like' : _reactionLabels[post.myReaction] ?? 'Liked',
                      color: post.myReaction == null ? null : scheme.primary,
                      onTap: () => feed.toggleLove(post.id),
                      onLongPress: () async {
                        final emoji = await showReactionPicker(context, current: post.myReaction);
                        if (emoji != null) feed.react(post.id, emoji);
                      },
                    ),
                  ),
                  Expanded(
                    child: _PostAction(
                      key: ValueKey('comment-${post.id}'),
                      icon: const Icon(Icons.mode_comment_outlined, size: 20),
                      label: 'Comment',
                      onTap: () => showCommentsSheet(
                        context,
                        title: 'Comments',
                        comments: (ref) => ref.watch(postProvider(post.id))?.comments ?? const [],
                        onSend: (ref, text) => ref.read(feedProvider.notifier).addComment(post.id, text),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PostAction(
                      key: ValueKey('send-${post.id}'),
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: 'Send',
                      onTap: () => showShareSheet(context, shareRef, onShared: () => feed.registerShare(post.id)),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('save-${post.id}'),
                    tooltip: post.saved ? 'Saved' : 'Save',
                    onPressed: () => feed.toggleSave(post.id),
                    icon: Icon(post.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    color: post.saved ? scheme.primary : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({super.key, required this.icon, required this.label, required this.onTap, this.onLongPress, this.color});

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: IconTheme.merge(
          data: IconThemeData(color: color),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PollView extends ConsumerWidget {
  const PollView({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final total = post.pollTotal;
    final voted = post.myVote != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < post.poll.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: voted
                  ? _PollResult(
                      label: post.poll[i].label,
                      fraction: total == 0 ? 0 : post.poll[i].votes / total,
                      selected: post.myVote == i,
                    )
                  : OutlinedButton(
                      key: ValueKey('vote-${post.id}-$i'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => ref.read(feedProvider.notifier).vote(post.id, i),
                      child: Text(post.poll[i].label),
                    ),
            ),
          const SizedBox(height: 4),
          Text(
            '${compactCount(total)} votes${voted ? '' : ' · tap to vote'}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PollResult extends StatelessWidget {
  const _PollResult({required this.label, required this.fraction, required this.selected});

  final String label;
  final double fraction;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(height: 42, color: scheme.surfaceContainerHighest),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 42,
                color: selected ? scheme.primary.withValues(alpha: 0.35) : scheme.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
                    ),
                  ),
                  if (selected) ...[
                    Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Text('${(fraction * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: post == null
          ? const Center(child: Text('This post is no longer available'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [PostCard(postId: postId)],
            ),
    );
  }
}
