import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/video.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/search/search_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';
import 'package:daily_motivation_ai/widgets/sheets.dart';

/// Long-form video (YouTube-style) with a Shorts shelf.
class WatchScreen extends ConsumerWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(watchCategoryProvider);
    final videos = ref.watch(videosProvider);
    final reels = ref.watch(reelsProvider);
    final visible = category == 'All' ? videos : videos.where((v) => v.category == category).toList();
    final saved = videos.where((v) => v.watchLater).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Row(
              children: [
                GradientMask(child: Icon(Icons.smart_display_rounded, size: 30, color: Colors.white)),
                SizedBox(width: 6),
                Text('Watch'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: videoCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = videoCategories[i];
                  return ChoiceChip(
                    label: Text(c),
                    selected: c == category,
                    showCheckmark: false,
                    onSelected: (_) => ref.read(watchCategoryProvider.notifier).state = c,
                  );
                },
              ),
            ),
          ),
          if (category == 'All') ...[
            const SliverToBoxAdapter(child: SectionHeader('Shorts', padding: EdgeInsets.fromLTRB(16, 12, 16, 8))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: reels.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final reel = reels[i];
                    return GestureDetector(
                      onTap: () => openReel(context, reel.id),
                      child: SizedBox(
                        width: 124,
                        child: ArtCanvas(
                          art: reel.art,
                          emojiSize: 48,
                          borderRadius: BorderRadius.circular(16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${reel.caption}\n${compactCount(reel.views)} views',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (saved.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Watch later')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: saved.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => SizedBox(
                      width: 200,
                      child: GestureDetector(
                        onTap: () => openVideo(context, saved[i].id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VideoThumbnail(video: saved[i]),
                            const SizedBox(height: 6),
                            Text(saved[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SectionHeader('For you')),
          ],
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, i) => VideoCard(key: ValueKey(visible[i].id), video: visible[i]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.video, this.radius = 14});

  final Video video;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ArtCanvas(
        art: video.art,
        emojiSize: 44,
        borderRadius: BorderRadius.circular(radius),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(6)),
            child: Text(
              formatDuration(video.durationSeconds),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoCard extends ConsumerWidget {
  const VideoCard({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(userProvider(video.channelId));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final notifier = ref.read(videosProvider.notifier);

    return InkWell(
      onTap: () => openVideo(context, video.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: VideoThumbnail(video: video, radius: 18)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => openProfile(context, channel.id),
                  child: OrbitAvatar(user: channel, size: 38),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.25),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${channel.name} · ${compactCount(video.views)} views · ${timeAgo(video.uploadedAt)}',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (value) {
                    if (value == 'later') notifier.toggleWatchLater(video.id);
                    if (value == 'share') {
                      showShareSheet(
                        context,
                        SharedRef(kind: SharedKind.video, id: video.id, ownerId: video.channelId, title: video.title, art: video.art),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'later', child: Text(video.watchLater ? 'Remove from Watch later' : 'Save to Watch later')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
