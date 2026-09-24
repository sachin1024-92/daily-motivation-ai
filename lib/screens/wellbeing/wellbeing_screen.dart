import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/providers/habits_provider.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/screens/focus_screen.dart';
import 'package:daily_motivation_ai/screens/habits_screen.dart';

/// Orbit's original Daily Motivation toolkit — habits, focus timer and the
/// AI coach — living inside the social app.
class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final done = habits.where((h) => h.completedToday).length;
    final best = habits.fold<int>(0, (a, h) => h.streak > a ? h.streak : a);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: const Text('Wellbeing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: OrbitColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: habits.isEmpty ? 0 : done / habits.length,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                      Center(
                        child: Text(
                          '$done/${habits.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mindful by design', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('$done of ${habits.length} habits done today', style: const TextStyle(color: Colors.white)),
                      Text('Best streak: $best days 🔥', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.checklist_rounded,
            title: 'Habits',
            subtitle: 'Track streaks and build routines',
            onTap: () => push(const HabitsScreen()),
          ),
          _Tile(
            icon: Icons.timer_rounded,
            title: 'Focus mode',
            subtitle: '25-minute Pomodoro sessions, no feed in sight',
            onTap: () => push(const FocusScreen()),
          ),
          _Tile(
            icon: Icons.auto_awesome_rounded,
            title: 'Talk to your AI coach',
            subtitle: 'Motivation, plans and accountability',
            onTap: () => openDirectChat(context, ref, orbitAiId),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Orbit ends your feed when you\'re caught up, never autoplays sound, and keeps your coach one tap away.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
