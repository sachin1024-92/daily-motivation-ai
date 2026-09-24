import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/video.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/watch/watch_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';
import 'package:daily_motivation_ai/widgets/sheets.dart';

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  static const _tick = Duration(milliseconds: 500);

  Timer? _ticker;
  double _position = 0;
  bool _playing = false;
  bool _controls = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _play();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(videosProvider.notifier).registerView(widget.videoId);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double get _duration => (ref.read(videoProvider(widget.videoId))?.durationSeconds ?? 1).toDouble();

  void _play() {
    if (_position >= _duration) _position = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        _position += _tick.inMilliseconds / 1000;
        if (_position >= _duration) {
          _position = _duration;
          _pause(rebuild: false);
        }
      });
    });
    setState(() => _playing = true);
  }

  void _pause({bool rebuild = true}) {
    _ticker?.cancel();
    _ticker = null;
    _playing = false;
    _controls = true;
    if (rebuild) setState(() {});
  }

  void _askAi(Video video) {
    final chats = ref.read(chatsProvider.notifier);
    final chatId = chats.ensureDirectChat(orbitAiId, title: 'Orbit AI');
    chats.send(
      chatId,
      'Summarize this for me ✨',
      attachment: SharedRef(kind: SharedKind.video, id: video.id, ownerId: video.channelId, title: video.title, art: video.art),
    );
    _pause();
    openChat(context, chatId);
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(videoProvider(widget.videoId));
    if (video == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This video is unavailable')));
    }
    final channel = ref.watch(userProvider(video.channelId));
    final subscribed = ref.watch(followingProvider).contains(video.channelId);
    final all = ref.watch(videosProvider);
    final upNext = all.where((v) => v.id != video.id).toList()
      ..sort((a, b) => (b.category == video.category ? 1 : 0) - (a.category == video.category ? 1 : 0));
    final videos = ref.read(videosProvider.notifier);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final shareRef = SharedRef(kind: SharedKind.video, id: video.id, ownerId: video.channelId, title: video.title, art: video.art);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: () => setState(() => _controls = !_controls),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LiveArtCanvas(art: video.art, playing: _playing, emojiSize: 72),
                    AnimatedOpacity(
                      opacity: _controls ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_controls,
                        child: Container(
                          color: Colors.black26,
                          child: Stack(
                            children: [
                              const Positioned(top: 4, left: 4, child: BackButton(color: Colors.white)),
                              Center(
                                child: IconButton(
                                  key: const ValueKey('video-play'),
                                  iconSize: 56,
                                  onPressed: _playing ? _pause : _play,
                                  icon: Icon(
                                    _playing
                                        ? Icons.pause_circle_filled_rounded
                                        : (_position >= _duration ? Icons.replay_circle_filled_rounded : Icons.play_circle_fill_rounded),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 4,
                                bottom: 0,
                                child: Row(
                                  children: [
                                    Text(
                                      '${formatDuration(_position.floor())} / ${formatDuration(video.durationSeconds)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 2.5,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: SliderComponentShape.noOverlay,
                                          activeTrackColor: const Color(0xFFFF3B6B),
                                          inactiveTrackColor: Colors.white30,
                                          thumbColor: const Color(0xFFFF3B6B),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          child: Slider(
                                            value: _position.clamp(0, video.durationSeconds.toDouble()),
                                            max: video.durationSeconds.toDouble(),
                                            onChanged: (v) => setState(() => _position = v),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Text(video.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '${compactCount(video.views)} views · ${timeAgo(video.uploadedAt)} ago · #${video.category.toLowerCase()}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: GestureDetector(
                      onTap: () => openProfile(context, channel.id),
                      child: OrbitAvatar(user: channel, size: 42),
                    ),
                    title: UserName(user: channel),
                    subtitle: Text('${compactCount(channel.followers + (subscribed ? 1 : 0))} subscribers'),
                    trailing: channel.id == meId
                        ? null
                        : subscribed
                            ? FilledButton.tonal(
                                onPressed: () => ref.read(followingProvider.notifier).toggle(channel.id),
                                child: const Text('Subscribed'),
                              )
                            : FilledButton(
                                key: const ValueKey('subscribe'),
                                onPressed: () => ref.read(followingProvider.notifier).toggle(channel.id),
                                child: const Text('Subscribe'),
                              ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _Pill(
                          key: const ValueKey('video-like'),
                          icon: video.liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                          label: compactCount(video.likes),
                          onTap: () => videos.toggleLike(video.id),
                        ),
                        _Pill(
                          icon: video.disliked ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                          label: 'Dislike',
                          onTap: () => videos.toggleDislike(video.id),
                        ),
                        _Pill(icon: Icons.send_rounded, label: 'Share', onTap: () => showShareSheet(context, shareRef)),
                        _Pill(icon: Icons.auto_awesome_rounded, label: 'Ask AI', onTap: () => _askAi(video)),
                        _Pill(
                          icon: video.watchLater ? Icons.watch_later_rounded : Icons.watch_later_outlined,
                          label: video.watchLater ? 'Saved' : 'Watch later',
                          onTap: () => videos.toggleWatchLater(video.id),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            video.description,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded ? null : TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Card(
                      child: ListTile(
                        title: Text('Comments · ${video.comments.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          video.comments.isEmpty ? 'Be the first to comment' : video.comments.last.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.unfold_more_rounded),
                        onTap: () => showCommentsSheet(
                          context,
                          title: 'Comments',
                          comments: (ref) => ref.watch(videoProvider(video.id))?.comments ?? const [],
                          onSend: (ref, text) => ref.read(videosProvider.notifier).addComment(video.id, text),
                        ),
                      ),
                    ),
                  ),
                  const SectionHeader('Up next'),
                  for (final next in upNext)
                    InkWell(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => VideoScreen(videoId: next.id)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 150, child: VideoThumbnail(video: next, radius: 12)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    next.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ref.watch(userProvider(next.channelId)).name}\n${compactCount(next.views)} views',
                                    style: TextStyle(color: muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: onTap,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
