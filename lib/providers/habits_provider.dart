import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:daily_motivation_ai/models/habit.dart';

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super([]) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString('habits');
    if (habitsJson != null) {
      final List decoded = jsonDecode(habitsJson);
      final today = DateTime.now();
      state = decoded
          .map((e) => rolloverHabit(Habit.fromJson(e), today))
          .toList();
      await _saveHabits();
    } else {
      // Default habits
      state = [
        const Habit(id: '1', title: 'Morning meditation', description: '10 minutes mindfulness'),
        const Habit(id: '2', title: 'Read 20 pages', description: 'Non-fiction or self-improvement'),
        const Habit(id: '3', title: 'Exercise / walk', description: 'Move your body daily'),
      ];
      await _saveHabits();
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((h) => h.toJson()).toList();
    await prefs.setString('habits', jsonEncode(jsonList));
  }

  Future<void> toggleHabit(String id) async {
    final today = DateTime.now();
    state = [
      for (final habit in state)
        if (habit.id == id) toggleHabitFor(habit, today) else habit,
    ];
    await _saveHabits();
  }

  Future<void> removeHabit(String id) async {
    state = state.where((habit) => habit.id != id).toList();
    await _saveHabits();
  }

  Future<void> addHabit(String title, String description) async {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
    );
    state = [...state, newHabit];
    await _saveHabits();
  }
}
