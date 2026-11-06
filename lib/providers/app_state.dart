import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_motivation_ai/models/quiz_result.dart';

// ---------------------------------------------------------------------------
// Profile: who the learner is and what they are preparing for.
// ---------------------------------------------------------------------------

class Profile {
  final String name;
  final String goalId;
  final bool onboarded;
  final bool loaded;

  const Profile({
    this.name = 'Learner',
    this.goalId = 'jee',
    this.onboarded = false,
    this.loaded = false,
  });

  Profile copyWith({String? name, String? goalId, bool? onboarded, bool? loaded}) =>
      Profile(
        name: name ?? this.name,
        goalId: goalId ?? this.goalId,
        onboarded: onboarded ?? this.onboarded,
        loaded: loaded ?? this.loaded,
      );
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, Profile>((ref) => ProfileNotifier());

class ProfileNotifier extends StateNotifier<Profile> {
  ProfileNotifier() : super(const Profile()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = Profile(
      name: prefs.getString('profile.name') ?? 'Learner',
      goalId: prefs.getString('profile.goal') ?? 'jee',
      onboarded: prefs.getBool('profile.onboarded') ?? false,
      loaded: true,
    );
  }

  Future<void> completeOnboarding(String name, String goalId) async {
    state = state.copyWith(
      name: name.trim().isEmpty ? 'Learner' : name.trim(),
      goalId: goalId,
      onboarded: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile.name', state.name);
    await prefs.setString('profile.goal', state.goalId);
    await prefs.setBool('profile.onboarded', true);
  }

  Future<void> setGoal(String goalId) async {
    state = state.copyWith(goalId: goalId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile.goal', goalId);
  }
}

// ---------------------------------------------------------------------------
// Progress: XP, streaks, lessons, test history, bookmarks, flashcards.
// ---------------------------------------------------------------------------

class Progress {
  final int xp;
  final int streak;
  final String? lastActiveDay;
  final Set<String> completedLessons;
  final Set<String> enrolledCourses;
  final List<QuizResult> results;
  final Set<String> bookmarkedQuestions;

  /// Leitner box (0-4) per flashcard id. Higher box = reviewed less often.
  final Map<String, int> cardBoxes;
  final int focusMinutes;
  final int doubtsAsked;

  const Progress({
    this.xp = 0,
    this.streak = 0,
    this.lastActiveDay,
    this.completedLessons = const {},
    this.enrolledCourses = const {},
    this.results = const [],
    this.bookmarkedQuestions = const {},
    this.cardBoxes = const {},
    this.focusMinutes = 0,
    this.doubtsAsked = 0,
  });

  int get level => 1 + xp ~/ 500;
  int get xpIntoLevel => xp % 500;

  Progress copyWith({
    int? xp,
    int? streak,
    String? lastActiveDay,
    Set<String>? completedLessons,
    Set<String>? enrolledCourses,
    List<QuizResult>? results,
    Set<String>? bookmarkedQuestions,
    Map<String, int>? cardBoxes,
    int? focusMinutes,
    int? doubtsAsked,
  }) =>
      Progress(
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
        completedLessons: completedLessons ?? this.completedLessons,
        enrolledCourses: enrolledCourses ?? this.enrolledCourses,
        results: results ?? this.results,
        bookmarkedQuestions: bookmarkedQuestions ?? this.bookmarkedQuestions,
        cardBoxes: cardBoxes ?? this.cardBoxes,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        doubtsAsked: doubtsAsked ?? this.doubtsAsked,
      );

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streak': streak,
        'lastActiveDay': lastActiveDay,
        'completedLessons': completedLessons.toList(),
        'enrolledCourses': enrolledCourses.toList(),
        'results': results.map((r) => r.toJson()).toList(),
        'bookmarks': bookmarkedQuestions.toList(),
        'cardBoxes': cardBoxes,
        'focusMinutes': focusMinutes,
        'doubtsAsked': doubtsAsked,
      };

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        xp: j['xp'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        lastActiveDay: j['lastActiveDay'] as String?,
        completedLessons: {...(j['completedLessons'] as List? ?? []).cast<String>()},
        enrolledCourses: {...(j['enrolledCourses'] as List? ?? []).cast<String>()},
        results: (j['results'] as List? ?? [])
            .map((e) => QuizResult.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        bookmarkedQuestions: {...(j['bookmarks'] as List? ?? []).cast<String>()},
        cardBoxes: Map<String, int>.from(j['cardBoxes'] as Map? ?? {}),
        focusMinutes: j['focusMinutes'] as int? ?? 0,
        doubtsAsked: j['doubtsAsked'] as int? ?? 0,
      );
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Progress>((ref) => ProgressNotifier());

class ProgressNotifier extends StateNotifier<Progress> {
  ProgressNotifier() : super(const Progress()) {
    _load();
  }

  static const _key = 'progress.v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && mounted) {
      try {
        state = Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  /// Adds XP and keeps the daily streak up to date.
  Future<void> addXp(int amount, {DateTime? now}) async {
    final today = dayKey(now ?? DateTime.now());
    var streak = state.streak;
    if (state.lastActiveDay != today) {
      final yesterday =
          dayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
      streak = state.lastActiveDay == yesterday ? streak + 1 : 1;
    }
    state = state.copyWith(xp: state.xp + amount, streak: streak, lastActiveDay: today);
    await _save();
  }

  Future<void> toggleLesson(String lessonId) async {
    final done = {...state.completedLessons};
    final added = done.add(lessonId);
    if (!added) done.remove(lessonId);
    state = state.copyWith(completedLessons: done);
    if (added) {
      await addXp(20);
    } else {
      await _save();
    }
  }

  Future<void> enroll(String courseId) async {
    state = state.copyWith(enrolledCourses: {...state.enrolledCourses, courseId});
    await addXp(10);
  }

  Future<void> recordResult(QuizResult result) async {
    final results = [result, ...state.results];
    state = state.copyWith(results: results.take(50).toList());
    await addXp(10 + result.correct * 5);
  }

  Future<void> toggleBookmark(String questionId) async {
    final b = {...state.bookmarkedQuestions};
    if (!b.remove(questionId)) b.add(questionId);
    state = state.copyWith(bookmarkedQuestions: b);
    await _save();
  }

  Future<void> reviewCard(String cardId, {required bool knewIt}) async {
    final boxes = {...state.cardBoxes};
    final current = boxes[cardId] ?? 0;
    boxes[cardId] = knewIt ? (current + 1).clamp(0, 4) : 0;
    state = state.copyWith(cardBoxes: boxes);
    await addXp(knewIt ? 3 : 1);
  }

  Future<void> addFocusMinutes(int minutes) async {
    state = state.copyWith(focusMinutes: state.focusMinutes + minutes);
    await addXp(minutes);
  }

  Future<void> countDoubt() async {
    state = state.copyWith(doubtsAsked: state.doubtsAsked + 1);
    await addXp(5);
  }
}
