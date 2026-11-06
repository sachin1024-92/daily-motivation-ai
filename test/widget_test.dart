import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_motivation_ai/data/courses.dart';
import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/data/study_content.dart';
import 'package:daily_motivation_ai/main.dart';
import 'package:daily_motivation_ai/models/quiz_result.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/practice/quiz_screen.dart';
import 'package:daily_motivation_ai/screens/practice/tools_screen.dart';
import 'package:daily_motivation_ai/services/ai_tutor_service.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: PrepVerseApp()));
  await tester.pumpAndSettle();
}

void main() {
  group('App shell', () {
    testWidgets('first launch shows onboarding and finishes into the app', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);

      expect(find.text('Welcome to PrepVerse AI'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Asha');
      await tester.tap(find.text('NEET (Medical)'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Start learning'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Start learning'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.textContaining('Asha'), findsWidgets);
    });

    testWidgets('returning learner lands on the five main tabs', (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile.onboarded': true,
        'profile.name': 'Ravi',
        'profile.goal': 'jee',
      });
      await pumpApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['Home', 'Learn', 'Practice', 'Doubts', 'Profile']) {
        expect(find.text(label), findsWidgets);
      }

      await tester.tap(find.text('Practice').last);
      await tester.pumpAndSettle();
      expect(find.text('Speed Quiz'), findsWidgets);
    });
  });

  group('Content integrity', () {
    test('every question has a valid answer index and explanation', () {
      final ids = <String>{};
      for (final q in questionBank) {
        expect(ids.add(q.id), isTrue, reason: 'duplicate id ${q.id}');
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
        expect(q.explanation, isNotEmpty);
      }
    });

    test('every goal has questions, flashcards and courses', () {
      for (final g in goals) {
        expect(questionsFor(g.id), isNotEmpty, reason: g.id);
        expect(flashcardsFor(g.id), isNotEmpty, reason: g.id);
        expect(coursesForGoal(g.id), isNotEmpty, reason: g.id);
      }
    });

    test('word rounds only contain words spellable from their letters', () {
      for (final round in wordRounds) {
        final pool = round.letters.toLowerCase().split('');
        for (final w in round.words) {
          final left = [...pool];
          for (final ch in w.split('')) {
            expect(left.remove(ch), isTrue, reason: '"$w" from ${round.letters}');
          }
        }
      }
    });

    test('lesson ids are unique across courses', () {
      final ids = [for (final c in courses) ...c.allLessons.map((l) => l.id)];
      expect(ids.toSet().length, ids.length);
    });
  });

  group('Logic', () {
    test('daily quiz is stable for a given day and goal', () {
      final day = DateTime(2026, 11, 6);
      final a = dailyQuestions('neet', day).map((q) => q.id).toList();
      final b = dailyQuestions('neet', day).map((q) => q.id).toList();
      expect(a, b);
      expect(a.length, 5);
    });

    test('quadratic solver handles real, equal and complex roots', () {
      expect(solveQuadratic(1, -5, 6), contains('x₁ = 3'));
      expect(solveQuadratic(1, -4, 4), contains('x = 2'));
      expect(solveQuadratic(1, 0, 1), contains('complex'));
    });

    test('streak grows on consecutive days and resets after a gap', () async {
      SharedPreferences.setMockInitialValues({});
      final n = ProgressNotifier();
      await n.addXp(10, now: DateTime(2026, 11, 1));
      await n.addXp(10, now: DateTime(2026, 11, 2));
      expect(n.state.streak, 2);
      await n.addXp(10, now: DateTime(2026, 11, 2));
      expect(n.state.streak, 2);
      await n.addXp(10, now: DateTime(2026, 11, 5));
      expect(n.state.streak, 1);
      expect(n.state.xp, 40);
    });

    test('quiz results round-trip through JSON', () {
      final r = QuizResult(
        title: 'Mock',
        mode: 'mock',
        date: DateTime(2026, 1, 1),
        total: 10,
        correct: 6,
        wrong: 2,
        score: 22,
        maxScore: 40,
        seconds: 300,
        topics: const {'Physics · Kinematics': TopicScore(3, 4)},
      );
      final back = QuizResult.fromJson(r.toJson());
      expect(back.skipped, 2);
      expect(back.score, 22);
      expect(back.topics['Physics · Kinematics']!.total, 4);
    });

    test('offline tutor finds relevant material', () {
      final answer = AiTutorService.offlineAnswer('What is the quadratic formula?');
      expect(answer, contains('Quadratic'));
      expect(AiTutorService.offlineAnswer('Make me a 7-day revision plan'),
          contains('Day 1'));
      expect(AiTutorService.offlineAnswer('What does the SA node do in the heart?'),
          contains('SA (sino-atrial) node'));
    });
  });

  testWidgets('practice quiz reveals explanation after answering', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final q = questionBank.first;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: QuizScreen(title: 'T', questions: [q], mode: QuizMode.practice),
      ),
    ));
    await tester.tap(find.text(q.options[q.answer]));
    await tester.pump();
    expect(find.textContaining(q.explanation), findsOneWidget);
  });
}
