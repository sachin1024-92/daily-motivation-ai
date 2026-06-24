class Habit {
  final String id;
  final String title;
  final String description;
  final int streak;
  final bool completedToday;

  const Habit({
    required this.id,
    required this.title,
    required this.description,
    this.streak = 0,
    this.completedToday = false,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    int? streak,
    bool? completedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'streak': streak,
        'completedToday': completedToday,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        streak: json['streak'] ?? 0,
        completedToday: json['completedToday'] ?? false,
      );
}
