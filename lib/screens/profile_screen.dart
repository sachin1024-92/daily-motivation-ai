import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/screens/focus_screen.dart';
import 'package:daily_motivation_ai/screens/habits_screen.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class Achievement {
  final String emoji;
  final String title;
  final bool earned;

  const Achievement(this.emoji, this.title, this.earned);
}

List<Achievement> badgesFor(Progress p) => [
      Achievement('🚀', 'First step', p.xp > 0),
      Achievement('🔥', '7-day streak', p.streak >= 7),
      Achievement('📚', '10 lessons', p.completedLessons.length >= 10),
      Achievement('🎯', 'First test', p.results.isNotEmpty),
      Achievement('💯', 'Perfect score', p.results.any((r) => r.total > 0 && r.correct == r.total)),
      Achievement('🧠', 'Curious mind (10 doubts)', p.doubtsAsked >= 10),
      Achievement('⏱️', 'Deep focus (5 h)', p.focusMinutes >= 300),
      Achievement('🏆', 'Level 5', p.level >= 5),
    ];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final p = ref.watch(progressProvider);
    final goal = goalById(profile.goalId);
    final theme = Theme.of(context);
    final avgAccuracy = p.results.isEmpty
        ? 0
        : (p.results.map((r) => r.accuracy).reduce((a, b) => a + b) / p.results.length * 100)
            .round();

    // Leaderboard: the learner among sample peers, ranked by XP.
    final board = [
      ('Aditi', 2840), ('Rahul', 2210), ('Sneha', 1675), ('Vikram', 1290),
      ('Zoya', 860), ('Arjun', 420), (profile.name, p.xp),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              child: Text(profile.name.isEmpty ? '?' : profile.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24)),
            ),
            title: Text(profile.name,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Level ${p.level} · ${p.xp} XP'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: StatTile(icon: Icons.local_fire_department, value: '${p.streak}', label: 'Day streak', color: Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: StatTile(icon: Icons.menu_book, value: '${p.completedLessons.length}', label: 'Lessons')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(icon: Icons.assignment_turned_in, value: '${p.results.length}', label: 'Tests')),
                const SizedBox(width: 8),
                Expanded(child: StatTile(icon: Icons.track_changes, value: '$avgAccuracy%', label: 'Accuracy', color: Colors.green)),
              ],
            ),
          ),
          const SectionHeader('Goal'),
          ListTile(
            leading: CircleAvatar(
                backgroundColor: goal.color, foregroundColor: Colors.white, child: Icon(goal.icon)),
            title: Text(goal.title),
            subtitle: Text(goal.subjects.join(' · ')),
            trailing: TextButton(
              child: const Text('Change'),
              onPressed: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (ctx) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in goals)
                      ListTile(
                        leading: Icon(g.icon, color: g.color),
                        title: Text(g.title),
                        subtitle: Text(g.subtitle),
                        selected: g.id == goal.id,
                        onTap: () {
                          ref.read(profileProvider.notifier).setGoal(g.id);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader('Study zone'),
          ListTile(
            leading: const Icon(Icons.checklist_rounded),
            title: const Text('Daily study targets'),
            subtitle: const Text('Habits with streaks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HabitsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.timer_rounded),
            title: const Text('Focus timer'),
            subtitle: Text('${p.focusMinutes} minutes focused so far'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusScreen())),
          ),
          const SectionHeader('Badges'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in badgesFor(p))
                  Chip(
                    avatar: Text(b.emoji),
                    label: Text(b.title),
                    backgroundColor: b.earned ? theme.colorScheme.primaryContainer : null,
                    labelStyle: TextStyle(
                        color: b.earned ? null : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          const SectionHeader('Leaderboard (this week)'),
          for (var i = 0; i < board.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: i < 3 ? Colors.amber : null,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(board[i].$1,
                  style: TextStyle(
                      fontWeight: board[i].$1 == profile.name ? FontWeight.bold : null)),
              trailing: Text('${board[i].$2} XP'),
              selected: board[i].$1 == profile.name,
            ),
          const SectionHeader('Settings'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Dark mode'),
            value: ref.watch(themeProvider) == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }
}
