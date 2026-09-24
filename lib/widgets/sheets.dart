import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/services/external_share.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';

// ---------------------------------------------------------------------------
// Reaction picker (Facebook-style)
// ---------------------------------------------------------------------------

Future<String?> showReactionPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Material(
          elevation: 10,
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < reactionEmojis.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 220 + i * 60),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) => Transform.scale(scale: t, child: child),
                    child: InkWell(
                      key: ValueKey('reaction-${reactionEmojis[i]}'),
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.pop(context, reactionEmojis[i]),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reactionEmojis[i] == current
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                        ),
                        child: Text(reactionEmojis[i], style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

Future<void> showCommentsSheet(
  BuildContext context, {
  required String title,
  required List<Comment> Function(WidgetRef ref) comments,
  required void Function(WidgetRef ref, String text) onSend,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CommentsSheet(title: title, comments: comments, onSend: onSend),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.title, required this.comments, required this.onSend});

  final String title;
  final List<Comment> Function(WidgetRef ref) comments;
  final void Function(WidgetRef ref, String text) onSend;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(ref, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.comments(ref);
    final me = ref.watch(profileProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: comments.isEmpty
                  ? Center(child: Text('No comments yet. Start the conversation 💬', style: TextStyle(color: muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        final author = ref.watch(userProvider(c.authorId));
                        return ListTile(
                          leading: OrbitAvatar(user: author, size: 36),
                          title: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '${author.handle}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: c.text),
                            ]),
                          ),
                          subtitle: Text(timeAgo(c.at), style: TextStyle(color: muted, fontSize: 12)),
                        );
                      },
                    ),
            ),
            const Divider(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    OrbitAvatar(user: me, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('comment-field'),
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Add a comment…'),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('comment-send'),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share anywhere: chats, groups, my channel, my story, or other apps
// ---------------------------------------------------------------------------

Future<void> showShareSheet(BuildContext context, SharedRef item, {VoidCallback? onShared}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ShareSheet(item: item, onShared: onShared),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.item, this.onShared});

  final SharedRef item;
  final VoidCallback? onShared;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final _selected = <String>{};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String get _externalText => '${widget.item.title}\n\nShared from Orbit ✨';

  void _done(String message) {
    widget.onShared?.call();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _send() {
    ref.read(chatsProvider.notifier).shareTo(_selected, widget.item, note: _note.text);
    final n = _selected.length;
    _done('Sent to $n ${n == 1 ? 'chat' : 'chats'}');
  }

  void _addToStory() {
    final item = widget.item;
    ref.read(storiesProvider.notifier).addToMyStory(
          StoryFrame(
            id: newId('s'),
            art: item.art ?? const MediaArt(colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)], emoji: '✨'),
            caption: item.title,
            at: DateTime.now(),
          ),
        );
    _done('Added to your story');
  }

  void _broadcast() {
    ref.read(chatsProvider.notifier).broadcast(_note.text, attachment: widget.item);
    _done('Broadcast to your channel');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final users = ref.watch(usersProvider);
    final chats = ref
        .watch(chatsProvider)
        .where((c) => c.joined && (c.kind != ChatKind.channel || c.ownerId == meId) && c.id != myChannelId)
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.lastActivity.compareTo(a.lastActivity);
      });
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (item.art != null)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ArtCanvas(art: item.art!, emojiSize: 20, borderRadius: BorderRadius.circular(12)),
                    ),
                  if (item.art != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share ${item.label.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: chats.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final chat = chats[i];
                  final selected = _selected.contains(chat.id);
                  return InkWell(
                    key: ValueKey('share-target-${chat.id}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => selected ? _selected.remove(chat.id) : _selected.add(chat.id)),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ChatAvatar(chat: chat, peer: users[chat.peerId], size: 54),
                              if (selected)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Your story', onTap: _addToStory),
                  _QuickAction(icon: Icons.campaign_outlined, label: 'My channel', onTap: _broadcast),
                  _QuickAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: _externalText));
                      _done('Copied to clipboard');
                    },
                  ),
                  _QuickAction(
                    icon: Icons.ios_share_rounded,
                    label: 'Other apps',
                    onTap: () {
                      widget.onShared?.call();
                      ExternalShare.share(context, _externalText, subject: 'From Orbit');
                    },
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _selected.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _note,
                              decoration: const InputDecoration(hintText: 'Add a message…'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            key: const ValueKey('share-send'),
                            onPressed: _send,
                            child: Text('Send (${_selected.length})'),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(icon, color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
