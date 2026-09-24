import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/search/search_screen.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

enum _ChatFilter { all, unread, groups, channels }

/// One inbox for 1:1 chats, groups, broadcast channels and the AI bot.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _ChatFilter.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          actions: [
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            IconButton(
              tooltip: 'New group',
              icon: const Icon(Icons.group_add_outlined),
              onPressed: () => _showNewGroup(context, ref),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Groups'),
              Tab(text: 'Channels'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ChatList(filter: _ChatFilter.all),
            _ChatList(filter: _ChatFilter.unread),
            _ChatList(filter: _ChatFilter.groups),
            _ChatList(filter: _ChatFilter.channels),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: const ValueKey('new-chat'),
          tooltip: 'New chat',
          onPressed: () => _showNewChat(context, ref),
          child: const Icon(Icons.edit_square),
        ),
      ),
    );
  }
}

class _ChatList extends ConsumerWidget {
  const _ChatList({required this.filter});

  final _ChatFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);
    final users = ref.watch(usersProvider);
    final joined = chats.where((c) => c.joined);
    final visible = switch (filter) {
      _ChatFilter.all => joined.toList(),
      _ChatFilter.unread => joined.where((c) => c.unread > 0).toList(),
      _ChatFilter.groups => joined.where((c) => c.kind == ChatKind.group).toList(),
      _ChatFilter.channels => joined.where((c) => c.kind == ChatKind.channel).toList(),
    }
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.lastActivity.compareTo(a.lastActivity);
      });
    final discover = filter == _ChatFilter.channels ? chats.where((c) => c.kind == ChatKind.channel && !c.joined).toList() : const <Chat>[];

    if (visible.isEmpty && discover.isEmpty) {
      return Center(
        child: Text(
          filter == _ChatFilter.unread ? 'You\'re all caught up 🎉' : 'Nothing here yet',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final chat in visible) _ChatTile(chat: chat, peer: users[chat.peerId], users: users),
        if (discover.isNotEmpty) ...[
          const SectionHeader('Discover channels'),
          for (final chat in discover)
            ListTile(
              leading: ChatAvatar(chat: chat, peer: null, size: 48),
              title: Text(chat.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${compactCount(chat.subscribers)} subscribers · ${chat.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: FilledButton.tonal(
                key: ValueKey('join-${chat.id}'),
                onPressed: () => ref.read(chatsProvider.notifier).toggleJoin(chat.id),
                child: const Text('Join'),
              ),
              onTap: () => openChat(context, chat.id),
            ),
        ],
      ],
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat, required this.peer, required this.users});

  final Chat chat;
  final OrbitUser? peer;
  final Map<String, OrbitUser> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final last = chat.lastMessage;
    final hasUnread = chat.unread > 0;

    Widget preview;
    if (chat.typing) {
      final who = chat.kind == ChatKind.group ? '${users[chat.typingUserId]?.name.split(' ').first ?? 'Someone'} is ' : '';
      preview = Text('${who}typing…', style: const TextStyle(color: OrbitColors.online, fontWeight: FontWeight.w600));
    } else if (last == null) {
      preview = Text(chat.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted));
    } else {
      final mine = last.senderId == meId;
      final sender = chat.kind == ChatKind.group && !mine ? '${users[last.senderId]?.name.split(' ').first}: ' : '';
      final body = last.text.isNotEmpty ? last.text : '📎 ${last.attachment?.label ?? 'Attachment'}';
      preview = Row(
        children: [
          if (mine && chat.kind != ChatKind.channel) ...[
            MessageTicks(status: last.status, size: 16, color: muted),
            const SizedBox(width: 3),
          ],
          Expanded(
            child: Text(
              '${mine && chat.kind == ChatKind.group ? 'You: ' : sender}$body',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: hasUnread ? scheme.onSurface : muted, fontWeight: hasUnread ? FontWeight.w600 : null),
            ),
          ),
        ],
      );
    }

    return ListTile(
      key: ValueKey('chat-${chat.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ChatAvatar(chat: chat, peer: peer, size: 52),
      title: Row(
        children: [
          if (chat.kind == ChatKind.channel) ...[
            Icon(Icons.campaign_rounded, size: 16, color: muted),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (peer?.verified ?? false) ...[
            const SizedBox(width: 3),
            const Icon(Icons.verified_rounded, size: 15, color: OrbitColors.verified),
          ],
          if (chat.muted) ...[
            const SizedBox(width: 4),
            Icon(Icons.volume_off_rounded, size: 15, color: muted),
          ],
        ],
      ),
      subtitle: preview,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            last == null ? '' : timeAgo(last.sentAt),
            style: TextStyle(fontSize: 12, color: hasUnread && !chat.muted ? scheme.primary : muted),
          ),
          const SizedBox(height: 6),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: chat.muted ? muted : scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unread}',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onPrimary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            )
          else if (chat.pinned)
            Icon(Icons.push_pin_rounded, size: 16, color: muted),
        ],
      ),
      onTap: () => openChat(context, chat.id),
      onLongPress: () => _showChatActions(context, ref, chat),
    );
  }
}

/// ✓ sent, ✓✓ delivered, blue ✓✓ read.
class MessageTicks extends StatelessWidget {
  const MessageTicks({super.key, required this.status, this.size = 15, this.color});

  final MessageStatus status;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => Icon(Icons.schedule_rounded, size: size, color: color),
      MessageStatus.sent => Icon(Icons.done_rounded, size: size, color: color),
      MessageStatus.delivered => Icon(Icons.done_all_rounded, size: size, color: color),
      MessageStatus.read => Icon(Icons.done_all_rounded, size: size, color: OrbitColors.readTick),
    };
  }
}

void _showChatActions(BuildContext context, WidgetRef ref, Chat chat) {
  final chats = ref.read(chatsProvider.notifier);
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(chat.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
            title: Text(chat.pinned ? 'Unpin' : 'Pin to top'),
            onTap: () {
              chats.togglePin(chat.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(chat.muted ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            title: Text(chat.muted ? 'Unmute' : 'Mute notifications'),
            onTap: () {
              chats.toggleMute(chat.id);
              Navigator.pop(context);
            },
          ),
          if (chat.unread > 0)
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined),
              title: const Text('Mark as read'),
              onTap: () {
                chats.markRead(chat.id);
                Navigator.pop(context);
              },
            ),
          if (chat.kind == ChatKind.channel && chat.ownerId != meId)
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Leave channel'),
              onTap: () {
                chats.toggleJoin(chat.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    ),
  );
}

void _showNewChat(BuildContext context, WidgetRef ref) {
  final users = ref.read(usersProvider).values.where((u) => u.id != meId).toList()
    ..sort((a, b) => a.isBot == b.isBot ? a.name.compareTo(b.name) : (a.isBot ? -1 : 1));
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('New chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group_add_rounded)),
            title: const Text('New group', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(sheetContext);
              _showNewGroup(context, ref);
            },
          ),
          for (final user in users)
            ListTile(
              leading: OrbitAvatar(user: user, size: 44, showOnline: true),
              title: UserName(user: user),
              subtitle: Text(user.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(sheetContext);
                openDirectChat(context, ref, user.id);
              },
            ),
        ],
      ),
    ),
  );
}

void _showNewGroup(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _NewGroupSheet(
      onCreated: (chatId) {
        Navigator.pop(sheetContext);
        openChat(context, chatId);
      },
    ),
  );
}

class _NewGroupSheet extends ConsumerStatefulWidget {
  const _NewGroupSheet({required this.onCreated});

  final ValueChanged<String> onCreated;

  @override
  ConsumerState<_NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends ConsumerState<_NewGroupSheet> {
  final _name = TextEditingController();
  final _picked = <String>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final art = MediaArt(
      colors: artPalettes[_name.text.length % artPalettes.length],
      emoji: '💬',
      seed: _name.text.length,
    );
    widget.onCreated(ref.read(chatsProvider.notifier).createGroup(_name.text, _picked.toList(), art));
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider).values.where((u) => u.id != meId && !u.isBot).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Group name', prefixIcon: Icon(Icons.groups_rounded)),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final user in users)
                  CheckboxListTile(
                    value: _picked.contains(user.id),
                    onChanged: (v) => setState(() => v! ? _picked.add(user.id) : _picked.remove(user.id)),
                    secondary: OrbitAvatar(user: user, size: 40),
                    title: Text(user.name),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _picked.isEmpty ? null : _create,
                child: Text(_picked.isEmpty ? 'Pick people' : 'Create group (${_picked.length + 1})'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
