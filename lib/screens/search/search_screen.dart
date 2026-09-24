import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

const _trending = ['travel', 'flutter', 'ramen', 'mobility', 'music', 'AI', 'photography'];

/// One search box across people, chats, posts, reels and videos.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    bool has(String s) => s.toLowerCase().contains(q);

    final users = ref.watch(usersProvider).values.where((u) => u.id != meId).toList();
    final following = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('search-field'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search people, posts, videos, chats',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: q.isEmpty ? null : IconButton(onPressed: _query.clear, icon: const Icon(Icons.close_rounded)),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: q.isEmpty ? _discover(users.where((u) => !following.contains(u.id)).toList()) : _results(has, users),
    );
  }

  Widget _discover(List<OrbitUser> suggestions) {
    return ListView(
      children: [
        const SectionHeader('Trending'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _trending)
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 18),
                  label: Text('#$t'),
                  onPressed: () => _query.text = t,
                ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SectionHeader('Suggested for you'),
          for (final user in suggestions)
            ListTile(
              leading: OrbitAvatar(user: user, size: 44),
              title: UserName(user: user),
              subtitle: Text('@${user.handle} · ${compactCount(user.followers)} followers'),
              trailing: FilledButton.tonal(
                onPressed: () => ref.read(followingProvider.notifier).toggle(user.id),
                child: const Text('Follow'),
              ),
              onTap: () => openProfile(context, user.id),
            ),
        ],
      ],
    );
  }

  Widget _results(bool Function(String) has, List<OrbitUser> users) {
    final people = users.where((u) => has(u.name) || has(u.handle) || has(u.bio)).toList();
    final chats = ref.watch(chatsProvider).where((c) => has(c.title) || has(c.description)).toList();
    final posts = ref.watch(feedProvider).where((p) => has(p.text) || has(p.location ?? '')).toList();
    final reels = ref.watch(reelsProvider).where((r) => has(r.caption) || has(r.audio)).toList();
    final videos = ref.watch(videosProvider).where((v) => has(v.title) || has(v.description) || has(v.category)).toList();
    final users0 = ref.watch(usersProvider);

    if (people.isEmpty && chats.isEmpty && posts.isEmpty && reels.isEmpty && videos.isEmpty) {
      return Center(child: Text('No results for "${_query.text.trim()}"'));
    }

    Widget thumb(Widget child) => SizedBox(width: 52, height: 52, child: child);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (people.isNotEmpty) ...[
          const SectionHeader('People'),
          for (final u in people)
            ListTile(
              leading: OrbitAvatar(user: u, size: 44),
              title: UserName(user: u),
              subtitle: Text('@${u.handle}'),
              onTap: () => openProfile(context, u.id),
            ),
        ],
        if (chats.isNotEmpty) ...[
          const SectionHeader('Chats & channels'),
          for (final c in chats)
            ListTile(
              leading: ChatAvatar(chat: c, peer: users0[c.peerId], size: 44),
              title: Text(c.title),
              subtitle: Text(c.description.isEmpty ? '${c.messages.length} messages' : c.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => openChat(context, c.id),
            ),
        ],
        if (posts.isNotEmpty) ...[
          const SectionHeader('Posts'),
          for (final p in posts)
            ListTile(
              leading: p.art == null
                  ? OrbitAvatar(user: users0[p.authorId]!, size: 44)
                  : thumb(ArtCanvas(art: p.art!, emojiSize: 22, borderRadius: BorderRadius.circular(12))),
              title: Text(p.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('@${users0[p.authorId]?.handle} · ${timeAgo(p.createdAt)}'),
              onTap: () => openPost(context, p.id),
            ),
        ],
        if (reels.isNotEmpty) ...[
          const SectionHeader('Reels'),
          for (final r in reels)
            ListTile(
              leading: thumb(ArtCanvas(art: r.art, emojiSize: 22, borderRadius: BorderRadius.circular(12))),
              title: Text(r.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${compactCount(r.views)} views'),
              onTap: () => openReel(context, r.id),
            ),
        ],
        if (videos.isNotEmpty) ...[
          const SectionHeader('Videos'),
          for (final v in videos)
            ListTile(
              leading: thumb(ArtCanvas(art: v.art, emojiSize: 22, borderRadius: BorderRadius.circular(12))),
              title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${users0[v.channelId]?.name} · ${formatDuration(v.durationSeconds)}'),
              onTap: () => openVideo(context, v.id),
            ),
        ],
      ],
    );
  }
}
