import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/reel.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/create/composer_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';
import 'package:daily_motivation_ai/widgets/sheets.dart';

/// Vertical short-video feed (Reels / Shorts). Tap to pause, double-tap to
/// like, swipe for the next one.
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key, this.initialReelId, this.standalone = false});

  final String? initialReelId;
  final bool standalone;

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  late final PageController _pages;
  late int _current;

  @override
  void initState() {
    super.initState();
    final reels = ref.read(reelsProvider);
    final index = widget.initialReelId == null ? 0 : reels.indexWhere((r) => r.id == widget.initialReelId);
    _current = math.max(index, 0);
    _pages = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);
    final visible = TickerMode.valuesOf(context).enabled;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => ReelPage(
              key: ValueKey(reels[i].id),
              reel: reels[i],
              active: visible && i == _current,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  if (widget.standalone) const BackButton(color: Colors.white) else const SizedBox(width: 12),
                  const Text(
                    'Reels',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Create a reel',
                    onPressed: () => openComposer(context, targets: {PublishTarget.reel}),
                    icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelPage extends ConsumerStatefulWidget {
  const ReelPage({super.key, required this.reel, required this.active});

  final Reel reel;
  final bool active;

  @override
  ConsumerState<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<ReelPage> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(covariant ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _paused = false;
      _start();
    } else if (!widget.active && oldWidget.active) {
      _clock.stop();
    }
  }

  void _start() {
    _clock.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(reelsProvider.notifier).registerView(widget.reel.id);
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _paused ? _clock.stop() : _clock.repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final author = ref.watch(userProvider(reel.authorId));
    final following = ref.watch(followingProvider).contains(reel.authorId);
    final reels = ref.read(reelsProvider.notifier);
    final shareRef = SharedRef(kind: SharedKind.reel, id: reel.id, ownerId: reel.authorId, title: reel.caption, art: reel.art);

    return Stack(
      fit: StackFit.expand,
      children: [
        DoubleTapLike(
          heartSize: 130,
          onTap: _togglePause,
          onDoubleTap: () => reels.like(reel.id),
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => ArtCanvas(
              art: reel.art,
              emojiSize: 140,
              phase: (_clock.value * 1.5) % 1,
            ),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
          ),
        ),
        if (_paused)
          const IgnorePointer(
            child: Center(child: Icon(Icons.play_arrow_rounded, size: 96, color: Colors.white70)),
          ),
        SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned(
                right: 6,
                bottom: 24,
                child: Column(
                  children: [
                    _ReelAction(
                      key: ValueKey('reel-like-${reel.id}'),
                      icon: reel.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: reel.liked ? const Color(0xFFFF3B6B) : Colors.white,
                      label: compactCount(reel.likes),
                      onTap: () => reels.toggleLike(reel.id),
                    ),
                    _ReelAction(
                      icon: Icons.mode_comment_outlined,
                      label: compactCount(reel.comments.length),
                      onTap: () => showCommentsSheet(
                        context,
                        title: 'Comments',
                        comments: (ref) {
                          for (final r in ref.watch(reelsProvider)) {
                            if (r.id == reel.id) return r.comments;
                          }
                          return const [];
                        },
                        onSend: (ref, text) => ref.read(reelsProvider.notifier).addComment(reel.id, text),
                      ),
                    ),
                    _ReelAction(
                      icon: Icons.send_rounded,
                      label: compactCount(reel.shares),
                      onTap: () => showShareSheet(context, shareRef, onShared: () => reels.registerShare(reel.id)),
                    ),
                    _ReelAction(
                      icon: reel.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      label: reel.saved ? 'Saved' : 'Save',
                      onTap: () => reels.toggleSave(reel.id),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _clock,
                      builder: (context, child) =>
                          Transform.rotate(angle: _clock.value * 2 * math.pi * 3, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: ArtAvatar(art: reel.art, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 80,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => openProfile(context, author.id),
                          child: OrbitAvatar(user: author, size: 34),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => openProfile(context, author.id),
                            child: UserName(
                              user: author.copyWith(name: author.handle),
                              color: Colors.white,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                        if (author.id != meId) ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => ref.read(followingProvider.notifier).toggle(author.id),
                            child: Text(following ? 'Following' : 'Follow'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reel.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reel.audio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${compactCount(reel.views)} views',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => LinearProgressIndicator(
              value: _clock.value,
              minHeight: 2,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReelAction extends StatelessWidget {
  const _ReelAction({super.key, required this.icon, required this.label, required this.onTap, this.color = Colors.white});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(
          children: [
            Icon(icon, color: color, size: 30, shadows: const [Shadow(color: Colors.black26, blurRadius: 8)]),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
