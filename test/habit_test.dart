import 'package:flutter_test/flutter_test.dart';
import 'package:daily_motivation_ai/models/habit.dart';

void main() {
  final monday = DateTime(2026, 11, 9);
  final tuesday = DateTime(2026, 11, 10);
  final thursday = DateTime(2026, 11, 12);
  const base = Habit(id: '1', title: 'Read', description: '');

  test('dayKey pads month and day', () {
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('completing a habit starts a streak and records the day', () {
    final done = toggleHabitFor(base, monday);
    expect(done.completedToday, isTrue);
    expect(done.streak, 1);
    expect(done.lastCompleted, '2026-11-09');
  });

  test('unticking the same day undoes the streak', () {
    final undone = toggleHabitFor(toggleHabitFor(base, monday), monday);
    expect(undone.completedToday, isFalse);
    expect(undone.streak, 0);
    expect(undone.lastCompleted, isNull);
  });

  test('next day clears the tick but keeps the streak', () {
    final next = rolloverHabit(toggleHabitFor(base, monday), tuesday);
    expect(next.completedToday, isFalse);
    expect(next.streak, 1);
    expect(toggleHabitFor(next, tuesday).streak, 2);
  });

  test('missing a day resets the streak', () {
    final later = rolloverHabit(toggleHabitFor(base, monday), thursday);
    expect(later.completedToday, isFalse);
    expect(later.streak, 0);
  });

  test('same-day reload changes nothing', () {
    final done = toggleHabitFor(base, monday);
    final reloaded = rolloverHabit(done, monday);
    expect(reloaded.completedToday, isTrue);
    expect(reloaded.streak, 1);
  });

  test('unticking today after a longer streak keeps yesterday', () {
    final day2 = toggleHabitFor(
        rolloverHabit(toggleHabitFor(base, monday), tuesday), tuesday);
    final undone = toggleHabitFor(day2, tuesday);
    expect(undone.streak, 1);
    expect(undone.lastCompleted, '2026-11-09');
    expect(rolloverHabit(undone, tuesday).streak, 1);
  });

  test('old saved data without a date keeps its streak', () {
    const legacy = Habit(
        id: '2', title: 'Walk', description: '', streak: 4, completedToday: true);
    final migrated = rolloverHabit(legacy, monday);
    expect(migrated.completedToday, isFalse);
    expect(migrated.streak, 4);
  });

  test('json round trip keeps lastCompleted', () {
    final done = toggleHabitFor(base, monday);
    expect(Habit.fromJson(done.toJson()).lastCompleted, '2026-11-09');
  });
}
