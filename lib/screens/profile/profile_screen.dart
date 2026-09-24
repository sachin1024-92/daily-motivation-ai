import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/models/world.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/screens/watch/watch_screen.dart';
import 'package:daily_motivation_ai/screens/wellbeing/wellbeing_screen.dart';
import 'package:daily_motivation_ai/services/external_share.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';
import 'package:daily_motivation_ai/widgets/sheets.dart';

enum _ProfileTab { posts, reels, videos, saved }

/// Instagram-style profile with a grid, plus the "worlds" you're on
/// elsewhere so people can find you on any app.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileTab _tab = _ProfileTab.posts;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider(widget.userId));
    final isMe = user.id == meId;
    final following = ref.watch(followingProvider);
    final isFollowing = following.contains(user.id);
    final posts = ref.watch(feedProvider).where((p) => p.authorId == user.id).toList();
    final saved = isMe ? ref.watch(feedProvider).where((p) => p.saved).toList() : const <Post>[];
    final reels = ref.watch(reelsProvider).where((r) => r.authorId == user.id).toList();
    final videos = ref.watch(videosProvider).where((v) => v.channelId == user.id).toList();
    final ring = ref.watch(storiesProvider.select((groups) {
      for (final g in groups) {
        if (g.userId == user.id) return isMe || !g.seen ? StoryRing.unseen : StoryRing.seen;
      }
      return StoryRing.none;
    }));
    final tabs = [
      _ProfileTab.posts,
      _ProfileTab.reels,
      if (videos.isNotEmpty) _ProfileTab.videos,
      if (isMe) _ProfileTab.saved,
    ];
    final tab = tabs.contains(_tab) ? _tab : _ProfileTab.posts;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text('@${user.handle}'),
        actions: [
          if (isMe) ...[
            IconButton(
              tooltip: 'Toggle theme',
              icon: const Icon(Icons.dark_mode_outlined),
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            IconButton(
              tooltip: 'Wellbeing',
              icon: const Icon(Icons.spa_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellbeingScreen())),
            ),
          ] else
            IconButton(
              tooltip: 'Share profile',
              icon: const Icon(Icons.send_rounded),
              onPressed: () => showShareSheet(
                context,
                SharedRef(
                  kind: SharedKind.profile,
                  id: user.id,
                  ownerId: user.id,
                  title: '${user.name} (@${user.handle})',
                  art: MediaArt(colors: user.colors, emoji: '👋'),
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: ring == StoryRing.none ? null : () => openStories(context, [user.id]),
                        child: OrbitAvatar(user: user, size: 84, ring: ring),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: StatLabel(value: '${posts.length + reels.length + videos.length}', label: 'Posts'),
                            ),
                            Expanded(
                              child: StatLabel(
                                value: compactCount(user.followers + (!isMe && isFollowing ? 1 : 0)),
                                label: 'Followers',
                              ),
                            ),
                            Expanded(
                              child: StatLabel(
                                value: compactCount(isMe ? following.length : user.following),
                                label: 'Following',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  UserName(user: user, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  if (user.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(user.bio, style: const TextStyle(height: 1.35)),
                    ),
                  if (user.worlds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final entry in user.worlds.entries)
                            ActionChip(
                              avatar: Icon(entry.key.icon, size: 16, color: entry.key.color),
                              label: Text(entry.key.label),
                              onPressed: () => ExternalShare.open(context, entry.key.profileUrl(entry.value)),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: isMe
                        ? [
                            Expanded(
                              child: FilledButton.tonal(
                                key: const ValueKey('edit-profile'),
                                onPressed: () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => _EditProfileSheet(user: user),
                                ),
                                child: const Text('Edit profile'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => ExternalShare.share(
                                  context,
                                  'Find me on Orbit: @${user.handle} ✨',
                                ),
                                child: const Text('Share profile'),
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: isFollowing
                                  ? FilledButton.tonal(
                                      key: const ValueKey('follow'),
                                      onPressed: () => ref.read(followingProvider.notifier).toggle(user.id),
                                      child: const Text('Following'),
                                    )
                                  : FilledButton(
                                      key: const ValueKey('follow'),
                                      onPressed: () => ref.read(followingProvider.notifier).toggle(user.id),
                                      child: const Text('Follow'),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const ValueKey('message'),
                                onPressed: () => openDirectChat(context, ref, user.id),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                  ),
                  if (isMe) const _WorldsCard(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  for (final t in tabs)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tab = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: t == tab ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Icon(
                            switch (t) {
                              _ProfileTab.posts => Icons.grid_on_rounded,
                              _ProfileTab.reels => Icons.slow_motion_video_rounded,
                              _ProfileTab.videos => Icons.smart_display_outlined,
                              _ProfileTab.saved => Icons.bookmark_border_rounded,
                            },
                            color: t == tab ? null : muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ...switch (tab) {
            _ProfileTab.posts => _postGrid(context, posts, 'No posts yet'),
            _ProfileTab.saved => _postGrid(context, saved, 'Save posts to see them here'),
            _ProfileTab.reels => reels.isEmpty
                ? [_empty(context, 'No reels yet')]
                : [
                    SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 9 / 16,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: reels.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => openReel(context, reels[i].id),
                        child: ArtCanvas(
                          art: reels[i].art,
                          emojiSize: 36,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                  Text(
                                    compactCount(reels[i].views),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
            _ProfileTab.videos => [
                SliverList.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, i) => VideoCard(video: videos[i]),
                ),
              ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<Widget> _postGrid(BuildContext context, List<Post> posts, String empty) {
    if (posts.isEmpty) return [_empty(context, empty)];
    return [
      SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: posts.length,
        itemBuilder: (context, i) {
          final post = posts[i];
          final author = ref.read(userProvider(post.authorId));
          return GestureDetector(
            onTap: () => openPost(context, post.id),
            child: ArtCanvas(
              art: post.art ?? MediaArt(colors: author.colors, emoji: '', seed: i),
              emojiSize: 34,
              showEmoji: post.art != null,
              child: Stack(
                children: [
                  if (post.art == null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        post.text,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (post.hasPoll)
                    const Positioned(top: 6, right: 6, child: Icon(Icons.poll_rounded, color: Colors.white, size: 18)),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _empty(BuildContext context, String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
}

/// Link your handles on other networks; they show on your profile and open
/// in their own apps.
class _WorldsCard extends ConsumerWidget {
  const _WorldsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(profileProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  GradientMask(child: Icon(Icons.hub_rounded, color: Colors.white)),
                  SizedBox(width: 8),
                  Text('Your worlds', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Link where else you are, so friends can reach you anywhere.', style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final world in World.values)
                    me.worlds.containsKey(world)
                        ? InputChip(
                            key: ValueKey('world-${world.name}'),
                            avatar: Icon(world.icon, size: 18, color: world.color),
                            label: Text(me.worlds[world]!),
                            onPressed: () => ExternalShare.open(context, world.profileUrl(me.worlds[world]!)),
                            onDeleted: () => ref.read(profileProvider.notifier).setWorld(world, null),
                          )
                        : ActionChip(
                            key: ValueKey('world-${world.name}'),
                            avatar: Icon(world.icon, size: 18, color: world.color),
                            label: Text('Link ${world.label}'),
                            onPressed: () async {
                              final handle = await showDialog<String>(
                                context: context,
                                builder: (_) => _LinkWorldDialog(world: world),
                              );
                              if (handle != null) ref.read(profileProvider.notifier).setWorld(world, handle);
                            },
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkWorldDialog extends StatefulWidget {
  const _LinkWorldDialog({required this.world});

  final World world;

  @override
  State<_LinkWorldDialog> createState() => _LinkWorldDialogState();
}

class _LinkWorldDialogState extends State<_LinkWorldDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.pop(context, value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(widget.world.icon, color: widget.world.color),
      title: Text('Link ${widget.world.label}'),
      content: TextField(
        key: const ValueKey('world-handle'),
        controller: _controller,
        autofocus: true,
        keyboardType: widget.world == World.whatsapp ? TextInputType.phone : TextInputType.text,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: widget.world.hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const ValueKey('world-save'), onPressed: _submit, child: const Text('Link')),
      ],
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final OrbitUser user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _handle = TextEditingController(text: widget.user.handle);
  late final _bio = TextEditingController(text: widget.user.bio);

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(controller: _handle, decoration: const InputDecoration(labelText: 'Username', prefixText: '@')),
          const SizedBox(height: 10),
          TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(profileProvider.notifier).update(name: _name.text, handle: _handle.text, bio: _bio.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
