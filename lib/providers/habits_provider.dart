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
      state = decoded.map((e) => Habit.fromJson(e)).toList();
    } else {
      // Default habits
      state = [
        const Habit(id: '1', title: 'Watch 1 lecture', description: 'Finish one lesson from your course'),
        const Habit(id: '2', title: 'Solve 20 questions', description: 'Speed quiz, DPP or mock section'),
        const Habit(id: '3', title: 'Revise flashcards', description: 'Clear today\'s spaced-repetition deck'),
        const Habit(id: '4', title: '2 focus sessions', description: '2 × 25-minute Pomodoros'),
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
    state = state.map((habit) {
      if (habit.id == id) {
        final newCompleted = !habit.completedToday;
        return habit.copyWith(
          completedToday: newCompleted,
          streak: newCompleted ? habit.streak + 1 : (habit.streak > 0 ? habit.streak - 1 : 0),
        );
      }
      return habit;
    }).toList();
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
