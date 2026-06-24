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
        const Habit(id: '1', title: 'Morning meditation', description: '10 minutes mindfulness', streak: 5),
        const Habit(id: '2', title: 'Read 20 pages', description: 'Non-fiction or self-improvement', streak: 12),
        const Habit(id: '3', title: 'Exercise / walk', description: 'Move your body daily', streak: 3),
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
