import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/app/shell.dart';
import 'package:daily_motivation_ai/main.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// The main vertical list of the visible tab (not its horizontal shelves).
Finder feedScrollable() =>
    find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(OrbitShell, skipOffstage: false)));

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: OrbitApp()));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App starts on the feed with the unified navigation', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Reels', 'Create', 'Watch', 'Chats']) {
      expect(navItem(label), findsOneWidget);
    }
    expect(find.text('Daily spark'), findsOneWidget);
    expect(find.text('Your story'), findsOneWidget);
    expect(find.byKey(const ValueKey('composer-prompt')), findsOneWidget);
  });

  testWidgets('Posts can be loved, then re-reacted from the picker', (tester) async {
    await pumpApp(tester);
    final react = find.byKey(const ValueKey('react-p1'));
    await tester.scrollUntilVisible(react, 300, scrollable: feedScrollable());
    await tester.ensureVisible(react);
    await tester.pumpAndSettle();

    await tester.tap(react);
    await tester.pump();
    expect(find.descendant(of: react, matching: find.text('Love')), findsOneWidget);

    await tester.longPress(react);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reaction-🔥')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: react, matching: find.text('Fire')), findsOneWidget);
  });

  testWidgets('Omni-post publishes to the feed from the Create button', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('nav-create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('composer-text')), 'Hello from one app ✨');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('target-channel')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('publish')));
    await tester.pumpAndSettle();

    expect(find.text('Hello from one app ✨'), findsOneWidget);
    expect(find.text('Published to Feed · My channel ✨'), findsOneWidget);
    final channel = containerOf(tester).read(chatProvider('c-my-channel'))!;
    expect(channel.lastMessage!.attachment!.kind, SharedKind.post);
  });

  testWidgets('Chats: open a DM, send a message, get read receipts and a reply', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Chats'));
    await tester.pumpAndSettle();

    expect(find.text('Orbit AI'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('chat-c-aisha')));
    await tester.pumpAndSettle();
    expect(find.text('Hiking trip this weekend? 🏔️'), findsOneWidget);

    // Smart replies suggest answers to the last incoming message.
    expect(find.text('What time?'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('chat-input')), 'Absolutely!');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pump();
    expect(find.text('Absolutely!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('typing…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Totally agree!'), findsOneWidget);

    final chat = containerOf(tester).read(chatProvider('c-aisha'))!;
    final mine = chat.messages.firstWhere((m) => m.text == 'Absolutely!');
    expect(mine.status, MessageStatus.read);
    expect(chat.unread, 0, reason: 'messages arriving while the chat is open are marked read');
  });

  testWidgets('Orbit AI replies inside the chat list', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-c-orbit-ai')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan my day 📋'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('simple plan'), findsOneWidget);
  });

  testWidgets('Channels can be discovered and joined', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Channels'));
    await tester.pumpAndSettle();

    expect(find.text('Discover channels'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('join-c-foodies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-c-foodies')), findsOneWidget);
    expect(containerOf(tester).read(chatProvider('c-foodies'))!.joined, isTrue);
  });

  testWidgets('Story replies land in the DM with the story attached', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('story-aisha')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Behind the scenes of today\'s shoot'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('story-reply')), 'Love this!');
    await tester.tap(find.byKey(const ValueKey('story-send')));
    await tester.pump();
    expect(find.text('Reply sent to Aisha'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-close')));
    await tester.pump(const Duration(milliseconds: 400));

    final chat = containerOf(tester).read(chatProvider('c-aisha'))!;
    final reply = chat.messages.firstWhere((m) => m.text == 'Love this!');
    expect(reply.attachment?.kind, SharedKind.story);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Watch: open a video and like it', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Watch'));
    await tester.pumpAndSettle();

    final title = find.text('I used only on-device AI for 30 days — here\'s what happened');
    await tester.scrollUntilVisible(title, 300, scrollable: feedScrollable());
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Up next'), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('video-like')));
    await tester.pump();
    expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('video-play')), warnIfMissed: false);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Profile: link another world and it persists', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('my-avatar')));
    await tester.pumpAndSettle();

    expect(find.text('@sachin'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('world-instagram')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('world-handle')), '@sachin.builds');
    await tester.tap(find.byKey(const ValueKey('world-save')));
    await tester.pumpAndSettle();

    expect(find.text('sachin.builds'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('profile')!) as Map<String, dynamic>;
    expect(saved['worlds'], {'instagram': 'sachin.builds'});
  });
}

