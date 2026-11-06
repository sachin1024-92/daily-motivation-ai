import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  String _goal = goals.first.id;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Icon(Icons.auto_awesome_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Welcome to PrepVerse AI',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Live classes, courses, mock tests, speed quizzes and a 24×7 AI tutor — all in one app.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),
            Text('What are you preparing for?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final g in goals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: _goal == g.id
                      ? g.color.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: g.color,
                      foregroundColor: Colors.white,
                      child: Icon(g.icon),
                    ),
                    title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(g.subtitle),
                    trailing: _goal == g.id
                        ? Icon(Icons.check_circle, color: g.color)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => setState(() => _goal = g.id),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(profileProvider.notifier)
                  .completeOnboarding(_name.text, _goal),
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Start learning'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
