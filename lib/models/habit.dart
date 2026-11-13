class Habit {
  final String id;
  final String title;
  final String description;
  final int streak;
  final bool completedToday;

  /// Day the habit was last completed, as `yyyy-MM-dd`. Null if never.
  final String? lastCompleted;

  const Habit({
    required this.id,
    required this.title,
    required this.description,
    this.streak = 0,
    this.completedToday = false,
    this.lastCompleted,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    int? streak,
    bool? completedToday,
    String? lastCompleted,
    bool clearLastCompleted = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
      lastCompleted:
          clearLastCompleted ? null : (lastCompleted ?? this.lastCompleted),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'streak': streak,
        'completedToday': completedToday,
        'lastCompleted': lastCompleted,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        streak: json['streak'] ?? 0,
        completedToday: json['completedToday'] ?? false,
        lastCompleted: json['lastCompleted'],
      );
}

/// `yyyy-MM-dd` key for a calendar day.
String dayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String _previousDayKey(DateTime date) =>
    dayKey(DateTime(date.year, date.month, date.day - 1));

/// Brings a stored habit up to date for [today]:
/// yesterday's tick is cleared, and the streak resets if a day was missed.
Habit rolloverHabit(Habit habit, DateTime today) {
  final last = habit.lastCompleted;
  if (last == null) {
    // Data saved before dates were tracked: keep the streak, start a new day.
    return habit.completedToday ? habit.copyWith(completedToday: false) : habit;
  }
  if (last == dayKey(today)) return habit;
  if (last == _previousDayKey(today)) {
    return habit.copyWith(completedToday: false);
  }
  return habit.copyWith(completedToday: false, streak: 0);
}

/// Ticks or unticks a habit for [today], keeping the streak consistent.
Habit toggleHabitFor(Habit habit, DateTime today) {
  if (!habit.completedToday) {
    return habit.copyWith(
      completedToday: true,
      streak: habit.streak + 1,
      lastCompleted: dayKey(today),
    );
  }
  final streak = habit.streak > 0 ? habit.streak - 1 : 0;
  if (streak == 0) {
    return habit.copyWith(
      completedToday: false,
      streak: 0,
      clearLastCompleted: true,
    );
  }
  return habit.copyWith(
    completedToday: false,
    streak: streak,
    lastCompleted: _previousDayKey(today),
  );
}
