import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/providers/app_providers.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/chats/chats_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';

const _aiStarters = ['Motivate me 🔥', 'Plan my day 📋', 'Caption ideas ✍️', 'Help me focus 🎯'];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _replyToId;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(chatsProvider.notifier).markRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    ref.read(chatsProvider.notifier).send(widget.chatId, value, replyToId: _replyToId);
    _input.clear();
    setState(() => _replyToId = null);
  }

  void _showMessageActions(Chat chat, Message message) {
    final chats = ref.read(chatsProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final emoji in reactionEmojis)
                    InkWell(
                      key: ValueKey('msg-react-$emoji'),
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        chats.react(chat.id, message.id, emoji);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            if (_canWrite(chat))
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyToId = message.id);
                  _focus.requestFocus();
                },
              ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(context);
                },
              ),
            if (message.attachment != null)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text('Open ${message.attachment!.label.toLowerCase()}'),
                onTap: () {
                  Navigator.pop(context);
                  openSharedRef(this.context, ref, message.attachment!);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _canWrite(Chat chat) => chat.kind != ChatKind.channel || chat.ownerId == meId;

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider(widget.chatId));
    if (chat == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Chat not found')));
    }
    ref.listen<int?>(chatProvider(widget.chatId).select((c) => c?.unread), (_, unread) {
      if ((unread ?? 0) > 0) ref.read(chatsProvider.notifier).markRead(widget.chatId);
    });

    final users = ref.watch(usersProvider);
    final peer = users[chat.peerId];
    final scheme = Theme.of(context).colorScheme;
    final messages = chat.messages;
    final byId = {for (final m in messages) m.id: m};
    final lastIncoming = messages.lastWhere((m) => m.senderId != meId, orElse: () => Message(id: '', senderId: '', text: '', sentAt: DateTime(0)));
    final suggestions = chat.kind == ChatKind.bot
        ? (messages.length <= 2 ? _aiStarters : const <String>[])
        : (_canWrite(chat) && messages.isNotEmpty && messages.last.senderId != meId && chat.kind != ChatKind.channel
            ? ref.read(grokServiceProvider).smartReplies(lastIncoming.text)
            : const <String>[]);

    final subtitle = switch (chat.kind) {
      _ when chat.typing =>
        chat.kind == ChatKind.group ? '${users[chat.typingUserId]?.name.split(' ').first ?? 'Someone'} is typing…' : 'typing…',
      ChatKind.direct => peer?.online ?? false ? 'online' : 'last seen recently',
      ChatKind.bot => 'AI assistant · always here',
      ChatKind.group => '${chat.memberIds.length} members',
      ChatKind.channel => '${compactCount(chat.subscribers)} subscribers',
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => peer != null ? openProfile(context, peer.id) : _showInfo(chat, users),
          child: Row(
            children: [
              ChatAvatar(chat: chat, peer: peer, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: chat.typing || subtitle == 'online' ? OrbitColors.online : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final chats = ref.read(chatsProvider.notifier);
              switch (value) {
                case 'pin':
                  chats.togglePin(chat.id);
                case 'mute':
                  chats.toggleMute(chat.id);
                case 'info':
                  _showInfo(chat, users);
                case 'leave':
                  chats.toggleJoin(chat.id);
                  Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Info')),
              PopupMenuItem(value: 'pin', child: Text(chat.pinned ? 'Unpin' : 'Pin')),
              PopupMenuItem(value: 'mute', child: Text(chat.muted ? 'Unmute' : 'Mute')),
              if (chat.kind == ChatKind.channel && chat.ownerId != meId && chat.joined)
                const PopupMenuItem(value: 'leave', child: Text('Leave channel')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final index = messages.length - 1 - i;
                final message = messages[index];
                final showDay = index == 0 || !isSameDay(messages[index - 1].sentAt, message.sentAt);
                return Column(
                  children: [
                    if (showDay) _DayChip(label: dayLabel(message.sentAt)),
                    MessageBubble(
                      key: ValueKey(message.id),
                      chat: chat,
                      message: message,
                      sender: users[message.senderId],
                      repliedTo: message.replyToId == null ? null : byId[message.replyToId],
                      users: users,
                      onLongPress: () => _showMessageActions(chat, message),
                    ),
                  ],
                );
              },
            ),
          ),
          if (suggestions.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) => ActionChip(
                  avatar: chat.kind == ChatKind.bot ? null : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(suggestions[i]),
                  onPressed: () => _send(suggestions[i]),
                ),
              ),
            ),
          if (_replyToId != null && byId[_replyToId] != null)
            _ReplyPreview(
              message: byId[_replyToId]!,
              sender: users[byId[_replyToId]!.senderId],
              onCancel: () => setState(() => _replyToId = null),
            ),
          SafeArea(
            top: false,
            child: _canWrite(chat)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('chat-input'),
                            controller: _input,
                            focusNode: _focus,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: switch (chat.kind) {
                                ChatKind.bot => 'Ask Orbit AI anything…',
                                ChatKind.channel => 'Broadcast to ${compactCount(chat.subscribers)} subscribers…',
                                _ => 'Message',
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedScale(
                          scale: _input.text.trim().isEmpty ? 0.85 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: OrbitColors.bubbleGradient),
                            child: IconButton(
                              key: const ValueKey('chat-send'),
                              onPressed: _input.text.trim().isEmpty ? null : _send,
                              icon: const Icon(Icons.send_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: chat.joined
                          ? OutlinedButton.icon(
                              onPressed: () => ref.read(chatsProvider.notifier).toggleMute(chat.id),
                              icon: Icon(chat.muted ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                              label: Text(chat.muted ? 'Unmute' : 'Mute'),
                            )
                          : FilledButton.icon(
                              key: const ValueKey('join-channel'),
                              onPressed: () => ref.read(chatsProvider.notifier).toggleJoin(chat.id),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Join channel'),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showInfo(Chat chat, Map<String, OrbitUser> users) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            Center(child: ChatAvatar(chat: chat, peer: users[chat.peerId], size: 84)),
            const SizedBox(height: 10),
            Center(child: Text(chat.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            if (chat.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Text(chat.description, textAlign: TextAlign.center),
              ),
            if (chat.kind == ChatKind.group) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text('Members', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              for (final id in chat.memberIds)
                if (users[id] != null)
                  ListTile(
                    leading: OrbitAvatar(user: users[id]!, size: 40, showOnline: true),
                    title: Text(id == meId ? 'You' : users[id]!.name),
                    subtitle: Text('@${users[id]!.handle}'),
                    onTap: id == meId ? null : () => openProfile(this.context, id),
                  ),
            ],
            if (chat.kind == ChatKind.channel)
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text('${compactCount(chat.subscribers)} subscribers'),
                subtitle: Text(chat.ownerId == meId ? 'You own this channel' : 'Broadcast channel · only admins post'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.sender, required this.onCancel});

  final Message message;
  final OrbitUser? sender;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderId == meId ? 'yourself' : sender?.name ?? ''}',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Text(
                  message.text.isNotEmpty ? message.text : '📎 ${message.attachment?.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(onPressed: onCancel, icon: const Icon(Icons.close_rounded, size: 18)),
        ],
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.chat,
    required this.message,
    required this.sender,
    required this.users,
    required this.onLongPress,
    this.repliedTo,
  });

  final Chat chat;
  final Message message;
  final OrbitUser? sender;
  final Message? repliedTo;
  final Map<String, OrbitUser> users;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.senderId == meId;
    final scheme = Theme.of(context).colorScheme;
    final isChannel = chat.kind == ChatKind.channel;
    final foreground = mine ? Colors.white : scheme.onSurface;
    final meta = mine ? Colors.white70 : scheme.onSurfaceVariant;
    final reactions = message.allReactions;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * (isChannel ? 0.88 : 0.78)),
        child: Padding(
          padding: EdgeInsets.only(top: 3, bottom: reactions.isEmpty ? 3 : 14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onLongPress: onLongPress,
                onDoubleTap: () => ref.read(chatsProvider.notifier).react(chat.id, message.id, '❤️'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    gradient: mine ? OrbitColors.bubbleGradient : null,
                    color: mine ? null : scheme.surface,
                    borderRadius: radius,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat.kind == ChatKind.group && !mine && sender != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            sender!.name,
                            style: TextStyle(color: sender!.colors.first, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      if (repliedTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          decoration: BoxDecoration(
                            color: (mine ? Colors.white : scheme.primary).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(left: BorderSide(color: mine ? Colors.white : scheme.primary, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                repliedTo!.senderId == meId ? 'You' : users[repliedTo!.senderId]?.name ?? '',
                                style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              Text(
                                repliedTo!.text.isNotEmpty ? repliedTo!.text : '📎 ${repliedTo!.attachment?.label}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: foreground.withValues(alpha: 0.85), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      if (message.attachment != null)
                        _AttachmentCard(item: message.attachment!, onTap: () => openSharedRef(context, ref, message.attachment!)),
                      if (message.text.isNotEmpty)
                        Text(message.text, style: TextStyle(color: foreground, fontSize: 15, height: 1.3)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isChannel) ...[
                            Icon(Icons.visibility_outlined, size: 13, color: meta),
                            const SizedBox(width: 3),
                            Text(compactCount(message.views), style: TextStyle(color: meta, fontSize: 11)),
                            const SizedBox(width: 8),
                          ],
                          Text(clockTime(message.sentAt), style: TextStyle(color: meta, fontSize: 11)),
                          if (mine && !isChannel) ...[
                            const SizedBox(width: 3),
                            MessageTicks(status: message.status, size: 15, color: meta),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (reactions.isNotEmpty)
                Positioned(
                  bottom: -12,
                  right: mine ? 10 : null,
                  left: mine ? null : 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                    ),
                    child: Text(
                      reactions.toSet().join() + (reactions.length > 1 ? ' ${reactions.length}' : ''),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.item, required this.onTap});

  final SharedRef item;
  final VoidCallback onTap;

  IconData get _icon => switch (item.kind) {
        SharedKind.post => Icons.article_rounded,
        SharedKind.reel => Icons.slow_motion_video_rounded,
        SharedKind.video => Icons.smart_display_rounded,
        SharedKind.story => Icons.amp_stories_rounded,
        SharedKind.profile => Icons.person_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final caption = Row(
      children: [
        Icon(_icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.title.isEmpty ? item.label : item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
    final tall = item.kind == SharedKind.reel || item.kind == SharedKind.story;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        key: ValueKey('attachment-${item.id}'),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 230,
            height: item.art == null ? null : (tall ? 200 : 130),
            child: item.art == null
                ? Container(color: Colors.black54, padding: const EdgeInsets.all(10), child: caption)
                : ArtCanvas(
                    art: item.art!,
                    emojiSize: 48,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        child: caption,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
