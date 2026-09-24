import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/providers/app_providers.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/services/grok_service.dart';

final chatsProvider = StateNotifierProvider<ChatsNotifier, List<Chat>>((ref) {
  return ChatsNotifier(ref.read(grokServiceProvider));
});

final chatProvider = Provider.family<Chat?, String>((ref, id) {
  for (final c in ref.watch(chatsProvider)) {
    if (c.id == id) return c;
  }
  return null;
});

/// Number of joined, unmuted chats with unread messages (the nav badge).
final unreadChatsProvider = Provider<int>((ref) {
  return ref.watch(chatsProvider).where((c) => c.joined && !c.muted && c.unread > 0).length;
});

/// WhatsApp + Telegram style messaging: 1:1 chats, groups, broadcast
/// channels and the Orbit AI bot, all in one list.
///
/// Delivery receipts, typing indicators and replies from other people are
/// simulated locally until a realtime backend is connected.
class ChatsNotifier extends StateNotifier<List<Chat>> {
  ChatsNotifier(
    this._ai, {
    List<Chat>? initial,
    this.replyDelay = const Duration(milliseconds: 1400),
  }) : super(initial ?? seedChats());

  final GrokService _ai;
  final Duration replyDelay;
  final Set<Timer> _timers = {};
  final Map<String, Timer> _pendingReplies = {};

  Chat? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _update(String id, Chat Function(Chat) change) {
    state = [for (final c in state) c.id == id ? change(c) : c];
  }

  Timer _after(Duration delay, void Function() action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (mounted) action();
    });
    _timers.add(timer);
    return timer;
  }

  // -- Sending ---------------------------------------------------------------

  /// Sends a message from me. Returns the new message id, or null when the
  /// message is empty or I can't post in this chat (someone else's channel).
  String? send(String chatId, String text, {SharedRef? attachment, String? replyToId}) {
    final chat = byId(chatId);
    if (chat == null || (text.trim().isEmpty && attachment == null)) return null;
    if (chat.kind == ChatKind.channel && chat.ownerId != meId) return null;

    final message = Message(
      id: newId('m'),
      senderId: meId,
      text: text.trim(),
      sentAt: DateTime.now(),
      status: MessageStatus.sent,
      replyToId: replyToId,
      attachment: attachment,
      views: chat.kind == ChatKind.channel ? 1 : 0,
    );
    _update(chatId, (c) => c.copyWith(messages: [...c.messages, message], unread: 0));

    switch (chat.kind) {
      case ChatKind.channel:
        _simulateViews(chatId, message.id, chat.subscribers);
      case ChatKind.bot:
        _askAi(chatId, message);
      case ChatKind.direct:
      case ChatKind.group:
        _simulateConversation(chat, message);
    }
    return message.id;
  }

  /// Sends any piece of Orbit content to several chats at once.
  void shareTo(Iterable<String> chatIds, SharedRef item, {String note = ''}) {
    for (final id in chatIds) {
      send(id, note, attachment: item);
    }
  }

  /// Posts to my own broadcast channel.
  void broadcast(String text, {SharedRef? attachment}) => send(myChannelId, text, attachment: attachment);

  void _setStatus(String chatId, MessageStatus status) {
    _update(
      chatId,
      (c) => c.copyWith(messages: [
        for (final m in c.messages)
          m.senderId == meId && m.status.index < status.index ? m.copyWith(status: status) : m,
      ]),
    );
  }

  void _simulateConversation(Chat chat, Message message) {
    final responderId = chat.kind == ChatKind.direct ? chat.peerId : _pickMember(chat, message);
    _after(replyDelay ~/ 3, () => _setStatus(chat.id, MessageStatus.delivered));
    if (responderId == null) return;

    // Only answer the latest message if I send several in a row.
    _pendingReplies.remove(chat.id)?.cancel();
    _after(replyDelay, () {
      _setStatus(chat.id, MessageStatus.read);
      _update(chat.id, (c) => c.copyWith(typingUserId: responderId));
    });
    _pendingReplies[chat.id] = _after(replyDelay * 2, () {
      _pendingReplies.remove(chat.id);
      _receive(chat.id, responderId, _replyFor(message));
    });
  }

  String? _pickMember(Chat chat, Message message) {
    final others = chat.memberIds.where((id) => id != meId).toList();
    if (others.isEmpty) return null;
    return others[(message.text.length + chat.messages.length) % others.length];
  }

  Future<void> _askAi(String chatId, Message message) async {
    _setStatus(chatId, MessageStatus.read);
    _update(chatId, (c) => c.copyWith(typingUserId: orbitAiId));
    final attachment = message.attachment;
    final prompt = attachment == null
        ? message.text
        : 'Give me a quick, upbeat take on this ${attachment.label.toLowerCase()}: "${attachment.title}". ${message.text}';
    final reply = await _ai.getMotivationResponse(prompt);
    if (!mounted) return;
    _after(replyDelay ~/ 2, () => _receive(chatId, orbitAiId, reply));
  }

  void _receive(String chatId, String senderId, String text) {
    final chat = byId(chatId);
    if (chat == null) return;
    final message = Message(id: newId('m'), senderId: senderId, text: text, sentAt: DateTime.now());
    _update(
      chatId,
      (c) => c.copyWith(messages: [...c.messages, message], unread: c.unread + 1, typingUserId: null),
    );
  }

  void _simulateViews(String chatId, String messageId, int subscribers) {
    void bump(int by) => _update(
          chatId,
          (c) => c.copyWith(messages: [
            for (final m in c.messages) m.id == messageId ? m.copyWith(views: m.views + by) : m,
          ]),
        );
    _after(replyDelay, () => bump((subscribers * 0.2).ceil()));
    _after(replyDelay * 3, () => bump((subscribers * 0.3).ceil()));
  }

  String _replyFor(Message message) {
    final text = message.text.toLowerCase();
    if (message.attachment != null) {
      return const ['Obsessed with this 🔥', 'Haha this is so good 😂', 'Saving this 🔖'][text.length % 3];
    }
    if (text.contains('hike') || text.contains('trip') || text.contains('weekend')) return 'Yes!! Count me in 🏔️';
    if (text.contains('?')) return 'Good question — let me think 🤔';
    if (text.contains('thank')) return 'Anytime! 😊';
    const replies = ['Haha love that 😂', 'Totally agree!', 'Omg yes 🙌', 'Say less 🔥', 'Sounds like a plan 👍'];
    return replies[text.length % replies.length];
  }

  // -- Chat management -------------------------------------------------------

  void markRead(String chatId) {
    final chat = byId(chatId);
    if (chat == null || chat.unread == 0) return;
    _update(chatId, (c) => c.copyWith(unread: 0));
  }

  void react(String chatId, String messageId, String emoji) {
    _update(
      chatId,
      (c) => c.copyWith(messages: [
        for (final m in c.messages)
          m.id == messageId ? m.copyWith(myReaction: m.myReaction == emoji ? null : emoji) : m,
      ]),
    );
  }

  void togglePin(String chatId) => _update(chatId, (c) => c.copyWith(pinned: !c.pinned));

  void toggleMute(String chatId) => _update(chatId, (c) => c.copyWith(muted: !c.muted));

  /// Join or leave a broadcast channel.
  void toggleJoin(String chatId) => _update(
        chatId,
        (c) => c.copyWith(
          joined: !c.joined,
          pinned: c.joined ? false : c.pinned,
          subscribers: c.subscribers + (c.joined ? -1 : 1),
          unread: 0,
        ),
      );

  /// Returns the 1:1 chat with [userId], creating it if needed.
  String ensureDirectChat(String userId, {required String title}) {
    for (final c in state) {
      if ((c.kind == ChatKind.direct || c.kind == ChatKind.bot) && c.peerId == userId) return c.id;
    }
    final chat = Chat(
      id: 'c-$userId',
      kind: userId == orbitAiId ? ChatKind.bot : ChatKind.direct,
      title: title,
      peerId: userId,
    );
    state = [chat, ...state];
    return chat.id;
  }

  String createGroup(String title, List<String> memberIds, MediaArt art) {
    final chat = Chat(
      id: newId('g'),
      kind: ChatKind.group,
      title: title.trim().isEmpty ? 'New group' : title.trim(),
      art: art,
      memberIds: [meId, ...memberIds],
      messages: [
        Message(id: newId('m'), senderId: meId, text: 'Created the group 👋', sentAt: DateTime.now()),
      ],
    );
    state = [chat, ...state];
    return chat.id;
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
