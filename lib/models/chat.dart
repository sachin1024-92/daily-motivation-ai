import 'package:daily_motivation_ai/models/media_art.dart';

const _keep = Object();

/// direct = WhatsApp-style 1:1, group = group chat, channel = Telegram-style
/// broadcast, bot = AI assistant living inside your chat list.
enum ChatKind { direct, group, channel, bot }

enum MessageStatus { sending, sent, delivered, read }

enum SharedKind { post, reel, video, story, profile }

/// A piece of Orbit content embedded in a chat message, so anything in the
/// app (a post, reel, video, story or profile) can be passed around in chats.
class SharedRef {
  final SharedKind kind;
  final String id;
  final String ownerId;
  final String title;
  final MediaArt? art;

  const SharedRef({
    required this.kind,
    required this.id,
    required this.ownerId,
    required this.title,
    this.art,
  });

  String get label => switch (kind) {
        SharedKind.post => 'Post',
        SharedKind.reel => 'Reel',
        SharedKind.video => 'Video',
        SharedKind.story => 'Story',
        SharedKind.profile => 'Profile',
      };
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;
  final List<String> reactions;
  final String? myReaction;
  final String? replyToId;
  final SharedRef? attachment;
  final int views;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.read,
    this.reactions = const [],
    this.myReaction,
    this.replyToId,
    this.attachment,
    this.views = 0,
  });

  /// Reactions from others plus mine, for display.
  List<String> get allReactions => [...reactions, if (myReaction != null) myReaction!];

  Message copyWith({MessageStatus? status, Object? myReaction = _keep, int? views}) {
    return Message(
      id: id,
      senderId: senderId,
      text: text,
      sentAt: sentAt,
      status: status ?? this.status,
      reactions: reactions,
      myReaction: identical(myReaction, _keep) ? this.myReaction : myReaction as String?,
      replyToId: replyToId,
      attachment: attachment,
      views: views ?? this.views,
    );
  }
}

class Chat {
  final String id;
  final ChatKind kind;
  final String title;
  final String description;
  final MediaArt? art;

  /// The other person for [ChatKind.direct] / [ChatKind.bot] chats.
  final String? peerId;
  final List<String> memberIds;
  final String? ownerId;
  final List<Message> messages;
  final int unread;
  final bool pinned;
  final bool muted;

  /// Who is currently typing, if anyone.
  final String? typingUserId;
  final bool joined;
  final int subscribers;

  const Chat({
    required this.id,
    required this.kind,
    required this.title,
    this.description = '',
    this.art,
    this.peerId,
    this.memberIds = const [],
    this.ownerId,
    this.messages = const [],
    this.unread = 0,
    this.pinned = false,
    this.muted = false,
    this.typingUserId,
    this.joined = true,
    this.subscribers = 0,
  });

  bool get typing => typingUserId != null;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  DateTime get lastActivity => lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Chat copyWith({
    List<Message>? messages,
    int? unread,
    bool? pinned,
    bool? muted,
    Object? typingUserId = _keep,
    bool? joined,
    int? subscribers,
  }) {
    return Chat(
      id: id,
      kind: kind,
      title: title,
      description: description,
      art: art,
      peerId: peerId,
      memberIds: memberIds,
      ownerId: ownerId,
      messages: messages ?? this.messages,
      unread: unread ?? this.unread,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      typingUserId: identical(typingUserId, _keep) ? this.typingUserId : typingUserId as String?,
      joined: joined ?? this.joined,
      subscribers: subscribers ?? this.subscribers,
    );
  }
}
