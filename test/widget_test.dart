import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/main.dart';

void main() {
  testWidgets('App starts and shows navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: DailyMotivationApp(),
      ),
    );

    // Verify that the bottom navigation is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify the four tabs exist by their labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
  });
}
