import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/courses.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/learn/lesson_screen.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class CourseDetailScreen extends ConsumerWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  IconData _icon(LessonType t) => switch (t) {
        LessonType.video => Icons.play_circle_fill_rounded,
        LessonType.notes => Icons.description_rounded,
        LessonType.practice => Icons.quiz_rounded,
      };

  Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    if (!course.isFree) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Unlock ${course.title}'),
          content: Text(
              'Price: ${formatInr(course.priceInr)}\n\nPayments are not connected in this build, '
              'so you can unlock the course for free to try it out.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlock')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(progressProvider.notifier).enroll(course.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enrolled in ${course.title} 🎉')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final enrolled = progress.enrolledCourses.contains(course.id);
    final lessons = course.allLessons;
    final done = lessons.where((l) => progress.completedLessons.contains(l.id)).length;
    final complete = lessons.isNotEmpty && done == lessons.length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.tagline, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${course.mentor} · ${course.weeks} weeks · '
                    '${(course.totalMinutes / 60).toStringAsFixed(1)} h of content'),
                const SizedBox(height: 4),
                Text('⭐ ${course.rating}  ·  ${formatCount(course.learners)} learners'),
                if (enrolled) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: lessons.isEmpty ? 0 : done / lessons.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  Text('$done of ${lessons.length} lessons complete'),
                ],
              ],
            ),
          ),
          if (complete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.amber.withValues(alpha: 0.25),
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                  title: const Text('Certificate unlocked!'),
                  subtitle: Text('You completed ${course.title}.'),
                  onTap: () => _showCertificate(context, ref),
                ),
              ),
            ),
          const SectionHeader('What you get'),
          for (final h in course.highlights)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text(h),
            ),
          const SectionHeader('Curriculum'),
          for (final ch in course.chapters)
            ExpansionTile(
              initiallyExpanded: ch == course.chapters.first,
              title: Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${ch.subject} · ${ch.lessons.length} lessons'),
              children: [
                for (final l in ch.lessons)
                  ListTile(
                    leading: Icon(_icon(l.type),
                        color: progress.completedLessons.contains(l.id)
                            ? Colors.green
                            : theme.colorScheme.primary),
                    title: Text(l.title),
                    subtitle: Text('${l.minutes} min · ${l.type.name}'),
                    trailing: !enrolled && l != course.allLessons.first
                        ? const Icon(Icons.lock_outline)
                        : progress.completedLessons.contains(l.id)
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.chevron_right),
                    onTap: () {
                      // First lesson is a free preview.
                      if (!enrolled && l != course.allLessons.first) {
                        _enroll(context, ref);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LessonScreen(lesson: l, chapter: ch)),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: enrolled
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => _enroll(context, ref),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(course.isFree
                      ? 'Enroll for free'
                      : 'Enroll · ${formatInr(course.priceInr)}'),
                ),
              ),
            ),
    );
  }

  void _showCertificate(BuildContext context, WidgetRef ref) {
    final name = ref.read(profileProvider).name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.amber),
        title: const Text('Certificate of Completion'),
        content: Text(
          'This certifies that\n\n$name\n\nhas completed\n\n${course.title}\n\n'
          '${MaterialLocalizations.of(ctx).formatMediumDate(DateTime.now())}',
          textAlign: TextAlign.center,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
