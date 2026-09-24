import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/activity/activity_screen.dart';
import 'package:daily_motivation_ai/screens/create/composer_screen.dart';
import 'package:daily_motivation_ai/screens/feed/daily_spark_card.dart';
import 'package:daily_motivation_ai/screens/feed/post_card.dart';
import 'package:daily_motivation_ai/screens/feed/stories_bar.dart';
import 'package:daily_motivation_ai/screens/search/search_screen.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

/// Home: stories on top, a daily spark, then the feed. Ends with a
/// "you're all caught up" marker instead of an infinite scroll.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedProvider);
    final filter = ref.watch(feedFilterProvider);
    final following = ref.watch(followingProvider);
    final me = ref.watch(profileProvider);
    final unread = ref.watch(unreadActivityProvider);

    final visible = switch (filter) {
      FeedFilter.forYou => posts,
      FeedFilter.following => posts.where((p) => p.authorId == meId || following.contains(p.authorId)).toList(),
      FeedFilter.saved => posts.where((p) => p.saved).toList(),
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const OrbitLogo(),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              IconButton(
                tooltip: 'Activity',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.favorite_border_rounded),
                ),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityScreen())),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: GestureDetector(
                  key: const ValueKey('my-avatar'),
                  onTap: () => openProfile(context, meId),
                  child: OrbitAvatar(user: me, size: 34),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: StoriesBar()),
          SliverToBoxAdapter(child: _ComposerPrompt(firstName: me.name.split(' ').first)),
          const SliverToBoxAdapter(child: DailySparkCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SegmentedButton<FeedFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: FeedFilter.forYou, label: Text('For you')),
                  ButtonSegment(value: FeedFilter.following, label: Text('Following')),
                  ButtonSegment(value: FeedFilter.saved, label: Text('Saved')),
                ],
                selected: {filter},
                onSelectionChanged: (s) => ref.read(feedFilterProvider.notifier).state = s.first,
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  filter == FeedFilter.saved ? 'Nothing saved yet. Tap 🔖 on any post.' : 'Follow people to fill this feed.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, i) => PostCard(key: ValueKey(visible[i].id), postId: visible[i].id),
            ),
          const SliverToBoxAdapter(child: _CaughtUp()),
        ],
      ),
    );
  }
}

class _ComposerPrompt extends StatelessWidget {
  const _ComposerPrompt({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Card(
        child: InkWell(
          key: const ValueKey('composer-prompt'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => openComposer(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'What\'s orbiting your mind, $firstName?',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.image_outlined, color: scheme.primary),
                const SizedBox(width: 14),
                Icon(Icons.poll_outlined, color: scheme.primary),
                const SizedBox(width: 14),
                IconButton(
                  tooltip: 'New reel',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => openComposer(context, targets: {PublishTarget.reel}),
                  icon: Icon(Icons.slow_motion_video_rounded, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        children: [
          const GradientMask(child: Icon(Icons.check_circle_rounded, size: 44, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('You\'re all caught up', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'That\'s everything new. Go live your life — we\'ll be here. 🌿',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
