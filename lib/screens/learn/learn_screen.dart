import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/courses.dart';
import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/learn/course_detail_screen.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = goalById(ref.watch(profileProvider).goalId);
    final enrolledIds = ref.watch(progressProvider).enrolledCourses;
    final forGoal = coursesForGoal(goal.id);
    final mine = courses.where((c) => enrolledIds.contains(c.id)).toList();

    List<Course> others(CourseKind kind) => courses.where((c) => c.kind == kind).toList()
      ..sort((a, b) => (b.goalIds.contains(goal.id) ? 1 : 0)
          .compareTo(a.goalIds.contains(goal.id) ? 1 : 0));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'My courses'),
              Tab(text: 'Career programs'),
              Tab(text: 'Free'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CourseList(courses: forGoal, empty: 'No courses for ${goal.title} yet.'),
            _CourseList(
                courses: mine, empty: 'You haven\'t enrolled yet. Pick a course from "For you".'),
            _CourseList(courses: others(CourseKind.program), empty: 'No programs yet.'),
            _CourseList(courses: others(CourseKind.free), empty: 'No free courses yet.'),
          ],
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  final List<Course> courses;
  final String empty;

  const _CourseList({required this.courses, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(empty, textAlign: TextAlign.center)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => CourseCard(course: courses[i]),
    );
  }
}

class CourseCard extends ConsumerWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enrolled = ref.watch(progressProvider).enrolledCourses.contains(course.id);
    final kindLabel = switch (course.kind) {
      CourseKind.batch => 'BATCH',
      CourseKind.program => 'CAREER PROGRAM',
      CourseKind.free => 'FREE',
    };
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ]),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(kindLabel,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(course.tagline, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('⭐ ${course.rating}'),
                      Text('👥 ${formatCount(course.learners)}'),
                      Text('🗓 ${course.weeks} weeks'),
                      Text(enrolled ? 'Enrolled ✓' : formatInr(course.priceInr),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
