import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/create/composer_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';

/// Full-screen stories: tap right/left to skip, hold to pause, swipe down to
/// close. Replies land in your 1:1 chat with the author, with the story
/// attached — just like Instagram and WhatsApp.
class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({super.key, required this.userIds, this.initialIndex = 0});

  final List<String> userIds;
  final int initialIndex;

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late int _group = widget.initialIndex.clamp(0, widget.userIds.length - 1);
  int _frame = 0;
  bool _closing = false;
  final _reply = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });

  String get _userId => widget.userIds[_group];

  StoryGroup? get _currentGroup => ref.read(storiesProvider.notifier).groupFor(_userId);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => _focus.hasFocus ? _progress.stop() : _progress.forward());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(storiesProvider.notifier).markSeen(_userId);
    });
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _reply.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _restart() => _progress.forward(from: 0);

  void _next() {
    final group = _currentGroup;
    if (group == null) return _close();
    if (_frame < group.frames.length - 1) {
      setState(() => _frame++);
      _restart();
    } else if (_group < widget.userIds.length - 1) {
      setState(() {
        _group++;
        _frame = 0;
      });
      ref.read(storiesProvider.notifier).markSeen(_userId);
      _restart();
    } else {
      _close();
    }
  }

  void _previous() {
    if (_frame > 0) {
      setState(() => _frame--);
    } else if (_group > 0) {
      setState(() {
        _group--;
        _frame = 0;
      });
    }
    _restart();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    _progress.stop();
    Navigator.of(context).maybePop();
  }

  void _sendReply(StoryFrame frame, String text) {
    if (text.trim().isEmpty) return;
    final user = ref.read(userProvider(_userId));
    final chats = ref.read(chatsProvider.notifier);
    final chatId = chats.ensureDirectChat(_userId, title: user.name);
    chats.send(
      chatId,
      text,
      attachment: SharedRef(
        kind: SharedKind.story,
        id: frame.id,
        ownerId: _userId,
        title: frame.caption,
        art: frame.art,
      ),
    );
    _reply.clear();
    _focus.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reply sent to ${user.name.split(' ').first}'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(storiesProvider);
    StoryGroup? group;
    for (final g in groups) {
      if (g.userId == _userId) group = g;
    }
    if (group == null || group.frames.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final frameIndex = _frame.clamp(0, group.frames.length - 1);
    final frame = group.frames[frameIndex];
    final user = ref.watch(userProvider(_userId));
    final isMe = _userId == meId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: const ValueKey('story-surface'),
                  onTapUp: (details) =>
                      details.localPosition.dx < constraints.maxWidth / 3 ? _previous() : _next(),
                  onLongPressStart: (_) => _progress.stop(),
                  onLongPressEnd: (_) => _progress.forward(),
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 300) _close();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ArtCanvas(key: ValueKey(frame.id), art: frame.art, emojiSize: 120),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black45, Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 4,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _progress,
                                builder: (context, _) => Row(
                                  children: [
                                    for (var i = 0; i < group!.frames.length; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: i < frameIndex ? 1 : (i == frameIndex ? _progress.value : 0),
                                              minHeight: 2.5,
                                              backgroundColor: Colors.white24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _progress.stop();
                                      openProfile(context, user.id);
                                    },
                                    child: OrbitAvatar(user: user, size: 34),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isMe ? 'Your story' : user.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(timeAgo(frame.at), style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: const ValueKey('story-close'),
                                    onPressed: _close,
                                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 36,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                frame.caption,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: isMe
                  ? Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        const Text('Seen by your close friends', style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            _progress.stop();
                            openComposer(context, targets: {PublishTarget.story});
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text('Add', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('story-reply'),
                            controller: _reply,
                            focusNode: _focus,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (text) => _sendReply(frame, text),
                            decoration: InputDecoration(
                              hintText: 'Reply to ${user.name.split(' ').first}…',
                              hintStyle: const TextStyle(color: Colors.white60),
                              fillColor: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Send a ❤️',
                          onPressed: () => _sendReply(frame, '❤️'),
                          icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
                        ),
                        IconButton(
                          key: const ValueKey('story-send'),
                          onPressed: () => _sendReply(frame, _reply.text),
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
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
