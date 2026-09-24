import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/models/quote.dart';
import 'package:daily_motivation_ai/providers/habits_provider.dart';
import 'package:daily_motivation_ai/screens/focus_screen.dart';
import 'package:daily_motivation_ai/screens/wellbeing/wellbeing_screen.dart';

/// Today's quote, with a one-tap path to your habits, focus timer, or to
/// post the quote yourself. The same quote shows all day.
Quote quoteOfTheDay([DateTime? now]) {
  final day = now ?? DateTime.now();
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return defaultQuotes[dayOfYear % defaultQuotes.length];
}

class DailySparkCard extends ConsumerWidget {
  const DailySparkCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = quoteOfTheDay();
    final habits = ref.watch(habitsProvider);
    final done = habits.where((h) => h.completedToday).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
      decoration: BoxDecoration(
        gradient: OrbitColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: OrbitColors.pink.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Daily spark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '“${quote.text}”',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(height: 6),
          Text('— ${quote.author}', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GlassChip(
                      icon: Icons.check_circle_rounded,
                      label: '$done/${habits.length} habits',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellbeingScreen())),
                    ),
                    _GlassChip(
                      icon: Icons.timer_rounded,
                      label: 'Focus',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusScreen())),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Post this spark',
                onPressed: () => openComposer(context, initialText: '“${quote.text}” — ${quote.author}'),
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
