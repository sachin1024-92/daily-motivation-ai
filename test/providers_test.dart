import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/models/world.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/services/grok_service.dart';
import 'package:daily_motivation_ai/utils/format.dart';

Post _post({Map<String, int> reactions = const {}, List<PollOption> poll = const []}) => Post(
      id: 'x',
      authorId: 'leo',
      text: 'hi',
      createdAt: DateTime(2026),
      reactions: reactions,
      poll: poll,
    );

void main() {
  group('FeedNotifier', () {
    test('reacting, switching and clearing reactions keeps counts right', () {
      final feed = FeedNotifier([_post(reactions: {'❤️': 2})]);

      feed.toggleLove('x');
      expect(feed.state.single.myReaction, '❤️');
      expect(feed.state.single.reactions, {'❤️': 3});

      feed.react('x', '🔥');
      expect(feed.state.single.myReaction, '🔥');
      expect(feed.state.single.reactions, {'❤️': 2, '🔥': 1});

      feed.react('x', '🔥');
      expect(feed.state.single.myReaction, isNull);
      expect(feed.state.single.reactions, {'❤️': 2});
    });

    test('a poll accepts exactly one vote', () {
      final feed = FeedNotifier([_post(poll: const [PollOption('a', 1), PollOption('b')])]);
      feed.vote('x', 1);
      feed.vote('x', 0);
      final post = feed.state.single;
      expect(post.myVote, 1);
      expect(post.poll.map((o) => o.votes), [1, 1]);
    });

    test('comments, saves and shares', () {
      final feed = FeedNotifier([_post()]);
      feed.addComment('x', '  nice  ');
      feed.addComment('x', '   ');
      feed.toggleSave('x');
      feed.registerShare('x');
      final post = feed.state.single;
      expect(post.comments.map((c) => c.text), ['nice']);
      expect(post.comments.single.authorId, meId);
      expect(post.saved, isTrue);
      expect(post.shares, 1);
    });
  });

  group('ChatsNotifier', () {
    late ChatsNotifier chats;

    setUp(() => chats = ChatsNotifier(GrokService(), replyDelay: const Duration(milliseconds: 100)));
    tearDown(() => chats.dispose());

    test('a DM gets delivered, read, and answered', () async {
      final id = chats.send('c-leo', 'See you at demo day?');
      expect(id, isNotNull);
      expect(chats.byId('c-leo')!.lastMessage!.status, MessageStatus.sent);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      final mid = chats.byId('c-leo')!;
      expect(mid.messages.firstWhere((m) => m.id == id).status, MessageStatus.read);
      expect(mid.typingUserId, 'leo');

      await Future<void>.delayed(const Duration(milliseconds: 110));
      final done = chats.byId('c-leo')!;
      expect(done.typing, isFalse);
      expect(done.lastMessage!.senderId, 'leo');
      expect(done.unread, 1);
    });

    test('only the owner can post in a channel', () {
      expect(chats.send('c-techpulse', 'hello'), isNull);
      expect(chats.send(myChannelId, 'hello subscribers'), isNotNull);
      expect(chats.byId(myChannelId)!.lastMessage!.views, 1);
    });

    test('empty messages are ignored', () {
      final before = chats.byId('c-leo')!.messages.length;
      expect(chats.send('c-leo', '   '), isNull);
      expect(chats.byId('c-leo')!.messages.length, before);
    });

    test('sharing sends the same content to several chats', () {
      const item = SharedRef(kind: SharedKind.video, id: 'v1', ownerId: 'techpulse', title: 'AI');
      chats.shareTo(['c-leo', 'c-hikers'], item, note: 'watch this');
      for (final id in ['c-leo', 'c-hikers']) {
        final last = chats.byId(id)!.lastMessage!;
        expect(last.attachment?.id, 'v1');
        expect(last.text, 'watch this');
      }
    });

    test('ensureDirectChat reuses existing chats and creates new ones once', () {
      expect(chats.ensureDirectChat('aisha', title: 'Aisha'), 'c-aisha');
      final created = chats.ensureDirectChat('nia', title: 'Nia Brooks');
      expect(chats.ensureDirectChat('nia', title: 'Nia Brooks'), created);
      expect(chats.state.where((c) => c.peerId == 'nia').length, 1);
      expect(chats.ensureDirectChat(orbitAiId, title: 'Orbit AI'), 'c-orbit-ai');
    });

    test('joining and leaving a channel updates subscribers', () {
      final before = chats.byId('c-foodies')!.subscribers;
      chats.toggleJoin('c-foodies');
      expect(chats.byId('c-foodies')!.joined, isTrue);
      expect(chats.byId('c-foodies')!.subscribers, before + 1);
      chats.toggleJoin('c-foodies');
      expect(chats.byId('c-foodies')!.joined, isFalse);
    });

    test('reacting to a message toggles my reaction', () {
      chats.react('c-hikers', 'm7', '😂');
      expect(chats.byId('c-hikers')!.messages.firstWhere((m) => m.id == 'm7').myReaction, '😂');
      chats.react('c-hikers', 'm7', '😂');
      expect(chats.byId('c-hikers')!.messages.firstWhere((m) => m.id == 'm7').myReaction, isNull);
    });

    test('groups include me as a member', () {
      final id = chats.createGroup('Book club', ['leo', 'mei'], const MediaArt(colors: [Color(0xFF000000)], emoji: '📚'));
      expect(chats.byId(id)!.memberIds, [meId, 'leo', 'mei']);
    });
  });

  group('StoriesNotifier', () {
    test('my story is always first and seen state updates', () {
      final stories = StoriesNotifier();
      stories.addToMyStory(StoryFrame(
        id: 'mine',
        art: const MediaArt(colors: [Color(0xFF000000)], emoji: '✨'),
        caption: 'hi',
        at: DateTime(2026),
      ));
      expect(stories.state.first.userId, meId);
      stories.markSeen('aisha');
      expect(stories.groupFor('aisha')!.seen, isTrue);
    });
  });

  group('ProfileNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('linking worlds normalises handles and can unlink', () async {
      final profile = ProfileNotifier();
      await profile.setWorld(World.telegram, ' @sachin ');
      expect(profile.state.worlds[World.telegram], 'sachin');
      await profile.setWorld(World.telegram, '');
      expect(profile.state.worlds, isEmpty);
    });

    test('edits are saved and restored', () async {
      await ProfileNotifier().update(name: 'Sachin K', bio: 'Hello');
      final restored = ProfileNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(restored.state.name, 'Sachin K');
      expect(restored.state.bio, 'Hello');
    });
  });

  group('World links', () {
    test('build public profile URLs', () {
      expect(World.instagram.profileUrl('@orbit').toString(), 'https://instagram.com/orbit');
      expect(World.telegram.profileUrl('orbit').toString(), 'https://t.me/orbit');
      expect(World.whatsapp.profileUrl('+1 (555) 010-0000').toString(), 'https://wa.me/15550100000');
      expect(World.youtube.profileUrl('orbit').toString(), 'https://youtube.com/@orbit');
    });
  });

  group('format', () {
    test('compactCount', () {
      expect(compactCount(999), '999');
      expect(compactCount(1200), '1.2K');
      expect(compactCount(3400000), '3.4M');
    });

    test('formatDuration', () {
      expect(formatDuration(65), '1:05');
      expect(formatDuration(3723), '1:02:03');
    });

    test('timeAgo', () {
      final now = DateTime(2026, 9, 24, 12);
      expect(timeAgo(now, now: now), 'now');
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m');
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h');
      expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d');
      expect(timeAgo(DateTime(2026, 3, 4), now: now), 'Mar 4');
    });
  });

  group('GrokService (offline)', () {
    test('smart replies match the message', () {
      final ai = GrokService();
      expect(ai.smartReplies('Hiking this weekend?'), contains('What time?'));
      expect(ai.smartReplies('thanks!'), contains('Anytime! 😊'));
    });

    test('magic caption keeps the draft', () async {
      final caption = await GrokService().suggestCaption('Sunset run');
      expect(caption, startsWith('Sunset run — '));
    });
  });
}
