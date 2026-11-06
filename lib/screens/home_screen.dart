import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/courses.dart';
import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/data/study_content.dart';
import 'package:daily_motivation_ai/models/quote.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/focus_screen.dart';
import 'package:daily_motivation_ai/screens/learn/course_detail_screen.dart';
import 'package:daily_motivation_ai/screens/live/live_class_screen.dart';
import 'package:daily_motivation_ai/screens/practice/flashcards_screen.dart';
import 'package:daily_motivation_ai/screens/practice/quiz_screen.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  final void Function(int tab) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final progress = ref.watch(progressProvider);
    final goal = goalById(profile.goalId);
    final now = DateTime.now();
    final live = liveClassesFor(goal.id, now);
    final quote = defaultQuotes[now.day % defaultQuotes.length];
    final gk = gkCapsules[now.day % gkCapsules.length];
    final goalCourses = coursesForGoal(goal.id);
    final enrolled = goalCourses.where((c) => progress.enrolledCourses.contains(c.id)).toList();
    final continueCourse = enrolled.isNotEmpty ? enrolled.first : null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_greeting()}, ${profile.name} 👋',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ActionChip(
                          avatar: Icon(goal.icon, size: 18, color: goal.color),
                          label: Text(goal.title),
                          onPressed: () => onNavigate(4),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 26)),
                      Text('${progress.streak} day', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),

            // Daily goal card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Level ${progress.level}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${progress.xp} XP'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.xpIntoLevel / 500,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text('${500 - progress.xpIntoLevel} XP to level ${progress.level + 1}. '
                          'Finish a lesson (+20) or a quiz (+5 per correct answer).'),
                    ],
                  ),
                ),
              ),
            ),

            // Quick actions
            const SectionHeader('Quick start'),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _quick(
                    context,
                    Icons.bolt_rounded,
                    'Speed Quiz',
                    '10 Qs · 20 sec each',
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          title: 'Speed Quiz',
                          questions: pickQuestions(questionsFor(goal.id), 10),
                          mode: QuizMode.speed,
                        ),
                      ),
                    ),
                  ),
                  _quick(
                    context,
                    Icons.today_rounded,
                    'Daily Quiz',
                    'Same 5 Qs for everyone today',
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          title: 'Daily Quiz',
                          questions: dailyQuestions(goal.id, now),
                          mode: QuizMode.practice,
                        ),
                      ),
                    ),
                  ),
                  _quick(
                    context,
                    Icons.style_rounded,
                    'Flashcards',
                    'Spaced repetition',
                    Colors.purple,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FlashcardsScreen())),
                  ),
                  _quick(
                    context,
                    Icons.psychology_alt_rounded,
                    'Ask a doubt',
                    'AI tutor, 24×7',
                    Colors.teal,
                    () => onNavigate(3),
                  ),
                  _quick(
                    context,
                    Icons.timer_rounded,
                    'Focus',
                    'Pomodoro study timer',
                    Colors.redAccent,
                    () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const FocusScreen())),
                  ),
                ],
              ),
            ),

            // Live classes
            SectionHeader('Live & upcoming classes',
                action: live.isEmpty ? null : 'See all',
                onAction: () => _showAllLive(context, live)),
            if (live.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No live classes scheduled for your goal today.'),
              )
            else
              for (final c in live.take(3)) _LiveTile(liveClass: c, now: now),

            // Continue learning
            SectionHeader(continueCourse == null ? 'Recommended for you' : 'Continue learning',
                action: 'Browse', onAction: () => onNavigate(1)),
            for (final c in (continueCourse == null ? goalCourses.take(2) : [continueCourse]))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _CourseProgressCard(course: c),
              ),

            // GK capsule + quote
            const SectionHeader('Today\'s capsule'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_rounded),
                  title: Text('${gk.category}: ${gk.title}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(gk.body),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('"${quote.text}"',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 6),
                      Text('— ${quote.author}', style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quick(BuildContext context, IconData icon, String title, String sub, Color color,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 140,
        child: FeatureTile(icon: icon, title: title, subtitle: sub, color: color, onTap: onTap),
      ),
    );
  }

  void _showAllLive(BuildContext context, List<LiveClass> live) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [for (final c in live) _LiveTile(liveClass: c, now: now)],
      ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  final LiveClass liveClass;
  final DateTime now;

  const _LiveTile({required this.liveClass, required this.now});

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.isLive(now);
    final t = TimeOfDay.fromDateTime(liveClass.start).format(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isLive ? Colors.red : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isLive ? Colors.white : null,
        child: Icon(isLive ? Icons.sensors_rounded : Icons.schedule_rounded),
      ),
      title: Text(liveClass.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${liveClass.subject} · ${liveClass.teacher} · $t · ${liveClass.minutes} min'),
      trailing: isLive
          ? FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LiveClassScreen(liveClass: liveClass))),
              child: const Text('Join'),
            )
          : OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reminder set for ${liveClass.title} at $t')),
              ),
              child: const Text('Remind'),
            ),
    );
  }
}

class _CourseProgressCard extends ConsumerWidget {
  final Course course;

  const _CourseProgressCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(progressProvider).completedLessons;
    final lessons = course.allLessons;
    final completed = lessons.where((l) => done.contains(l.id)).length;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(course.tagline, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: lessons.isEmpty ? 0 : completed / lessons.length,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 4),
              Text('$completed / ${lessons.length} lessons',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
