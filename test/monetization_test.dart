import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/app/shell.dart';
import 'package:daily_motivation_ai/main.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';
import 'package:daily_motivation_ai/services/ads_service.dart';
import 'package:daily_motivation_ai/services/billing_service.dart';

/// A Play store stand-in: two plans, and purchases succeed instantly.
class FakePlusStore implements PlusStore {
  FakePlusStore({this.ownsPlus = false});

  bool ownsPlus;
  final _events = StreamController<PlusEvent>.broadcast();
  final List<String> bought = [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<PlusPlan>> loadPlans() async => const [
        PlusPlan(id: plusMonthlyId, title: 'Monthly', price: '₹99', rawPrice: 99, currencyCode: 'INR'),
        PlusPlan(id: plusYearlyId, title: 'Yearly', price: '₹799', rawPrice: 799, currencyCode: 'INR'),
      ];

  @override
  Future<void> buy(String planId) async {
    bought.add(planId);
    ownsPlus = true;
    _events.add(const PlusEvent(PlusEventType.granted));
  }

  @override
  Future<void> refresh() async => _events.add(PlusEvent(ownsPlus ? PlusEventType.granted : PlusEventType.revoked));

  @override
  Stream<PlusEvent> get events => _events.stream;

  @override
  void dispose() => _events.close();
}

Future<ProviderContainer> pumpOrbit(WidgetTester tester, {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: const OrbitApp()));
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(OrbitShell, skipOffstage: false)));
}

Finder feedScrollable() =>
    find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;

Finder navItem(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

String today() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'welcome_seen': true}));

  testWidgets('First launch shows the preview welcome once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpOrbit(tester);
    await tester.pumpAndSettle();

    expect(find.text('You\'re in the preview'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    expect(find.text('You\'re in the preview'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('welcome_seen'), isTrue);
  });

  testWidgets('Requesting a service opens a chat with the provider', (tester) async {
    final container = await pumpOrbit(tester);
    await tester.tap(find.byKey(const ValueKey('open-services')));
    await tester.pumpAndSettle();

    expect(find.text('1:1 mobility coaching'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('request-sv1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomorrow'));
    await tester.enterText(find.byKey(const ValueKey('request-note')), 'Lower back is stiff');
    await tester.tap(find.byKey(const ValueKey('request-send')));
    await tester.pumpAndSettle();

    final chatId = container.read(chatsProvider).firstWhere((c) => c.peerId == 'rohan').id;
    final request = container.read(chatProvider(chatId))!.messages.last;
    expect(request.attachment?.kind, SharedKind.service);
    expect(request.text, contains('Preferred time: Tomorrow'));
    expect(request.text, contains('Lower back is stiff'));
    expect(find.text('Sample conversation: replies are simulated in the Orbit preview'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('I have openings tomorrow'), findsOneWidget);
  });

  testWidgets('People can list their own service', (tester) async {
    final container = await pumpOrbit(tester);
    await tester.tap(find.byKey(const ValueKey('open-services')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offer-service')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('service-title')), 'Resume review');
    await tester.enterText(find.byKey(const ValueKey('service-price')), '349');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('publish-service')));
    await tester.pumpAndSettle();

    final mine = container.read(servicesProvider).first;
    expect(mine.title, 'Resume review');
    expect(mine.price, 349);
    expect(mine.featured, isFalse, reason: 'featuring is a Plus perk');
    expect(find.text('Resume review'), findsOneWidget);
  });

  testWidgets('Paywall explains when Google Play is not available', (tester) async {
    await pumpOrbit(tester);
    await tester.tap(find.byKey(const ValueKey('my-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orbit Plus'));
    await tester.pumpAndSettle();

    expect(find.textContaining('sold through Google Play'), findsOneWidget);
    expect(find.byKey(const ValueKey('plus-subscribe')), findsNothing);
  });

  testWidgets('Subscribing unlocks Plus and hides ads', (tester) async {
    final store = FakePlusStore();
    final container = await pumpOrbit(tester, overrides: [
      plusStoreProvider.overrideWithValue(store),
      adsConfigProvider.overrideWithValue(const AdsConfig(enabled: true, feedUnitId: 'test')),
    ]);
    expect(container.read(showAdsProvider), isTrue);
    final ad = find.byType(FeedAdCard);
    await tester.scrollUntilVisible(ad, 400, scrollable: feedScrollable());
    expect(ad, findsWidgets);
    await tester.drag(feedScrollable(), const Offset(0, 6000));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('my-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orbit Plus'));
    await tester.pumpAndSettle();

    expect(find.text('₹799/yr'), findsOneWidget);
    expect(find.text('Save 33%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plus-subscribe')));
    await tester.pumpAndSettle();

    expect(store.bought, [plusYearlyId], reason: 'yearly is preselected');
    expect(container.read(isPlusProvider), isTrue);
    expect(container.read(showAdsProvider), isFalse);
    expect(container.read(aiMessagesLeftProvider), isNull, reason: 'Plus has unlimited AI');
    expect(find.text('You\'re on Orbit Plus'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('plus_active'), isTrue);
  });

  testWidgets('An expired subscription is removed on the next check', (tester) async {
    SharedPreferences.setMockInitialValues({'welcome_seen': true, 'plus_active': true});
    final container = await pumpOrbit(tester, overrides: [plusStoreProvider.overrideWithValue(FakePlusStore())]);
    await tester.pumpAndSettle();
    expect(container.read(isPlusProvider), isFalse);
  });

  testWidgets('Free users hit the paywall after the daily AI allowance', (tester) async {
    SharedPreferences.setMockInitialValues({'welcome_seen': true, 'ai_quota': '${today()}|$freeAiMessagesPerDay'});
    final container = await pumpOrbit(tester);
    container.read(aiMessagesLeftProvider); // creates the quota, which loads from storage
    await tester.pumpAndSettle();
    expect(container.read(aiMessagesLeftProvider), 0);

    await tester.tap(navItem('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-c-orbit-ai')));
    await tester.pumpAndSettle();
    final before = container.read(chatProvider('c-orbit-ai'))!.messages.length;

    await tester.tap(find.text('Motivate me 🔥'));
    await tester.pumpAndSettle();
    expect(find.textContaining('free Orbit AI messages'), findsOneWidget);
    expect(container.read(chatProvider('c-orbit-ai'))!.messages.length, before);
  });

  testWidgets('Each AI message spends one free message', (tester) async {
    final container = await pumpOrbit(tester);
    await tester.tap(navItem('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-c-orbit-ai')));
    await tester.pumpAndSettle();
    expect(find.text('Ask Orbit AI · $freeAiMessagesPerDay free today'), findsOneWidget);

    await tester.tap(find.text('Motivate me 🔥'));
    await tester.pump();
    expect(container.read(aiMessagesLeftProvider), freeAiMessagesPerDay - 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Premium vibes are locked for free users', (tester) async {
    await pumpOrbit(tester);
    await tester.tap(find.byKey(const ValueKey('nav-create')));
    await tester.pumpAndSettle();
    final premium = find.byKey(const ValueKey('palette-10'));
    // Pin the swatch row itself: palette-0 unloads once the row scrolls.
    final row = find.ancestor(of: find.byKey(const ValueKey('palette-0')), matching: find.byType(Scrollable)).first;
    final swatches = find.byWidget(tester.widget(row));
    await tester.scrollUntilVisible(premium, 200, scrollable: swatches);
    await tester.tap(premium);
    await tester.pumpAndSettle();
    expect(find.text('Premium vibes are part of Orbit Plus.'), findsOneWidget);
  });

  testWidgets('Delete my data clears stored settings', (tester) async {
    SharedPreferences.setMockInitialValues({'welcome_seen': true, 'isDarkMode': true});
    await pumpOrbit(tester);
    await tester.tap(find.byKey(const ValueKey('my-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('isDarkMode'), isNull);
    expect(find.text('Your data on this device was deleted'), findsOneWidget);
  });
}
