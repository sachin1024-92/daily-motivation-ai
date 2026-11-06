import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/practice/flashcards_screen.dart';
import 'package:daily_motivation_ai/screens/practice/quiz_screen.dart';
import 'package:daily_motivation_ai/screens/practice/tools_screen.dart';
import 'package:daily_motivation_ai/screens/practice/word_builder_screen.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  void _start(BuildContext context, String title, List<Question> qs, QuizMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(title: title, questions: qs, mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = goalById(ref.watch(profileProvider).goalId);
    final progress = ref.watch(progressProvider);
    final pool = questionsFor(goal.id);
    final subjects = subjectsWithQuestions(goal.id);
    final bookmarked =
        questionBank.where((q) => progress.bookmarkedQuestions.contains(q.id)).toList();

    final features = [
      FeatureTile(
        icon: Icons.bolt_rounded,
        title: 'Speed Quiz',
        subtitle: '20 seconds per question',
        color: Colors.orange,
        onTap: () => _start(context, 'Speed Quiz', pickQuestions(pool, 10), QuizMode.speed),
      ),
      FeatureTile(
        icon: Icons.assignment_rounded,
        title: 'Full Mock Test',
        subtitle: '+4 / −1 · exam timer',
        color: Colors.indigo,
        onTap: () => _start(context, '${goal.title} Mock Test', pickQuestions(pool, 20),
            QuizMode.mock),
      ),
      FeatureTile(
        icon: Icons.today_rounded,
        title: 'Daily Quiz',
        subtitle: '5 fresh questions daily',
        color: Colors.blue,
        onTap: () => _start(context, 'Daily Quiz', dailyQuestions(goal.id, DateTime.now()),
            QuizMode.practice),
      ),
      FeatureTile(
        icon: Icons.style_rounded,
        title: 'Flashcards',
        subtitle: 'Formulas & facts, spaced',
        color: Colors.purple,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const FlashcardsScreen())),
      ),
      FeatureTile(
        icon: Icons.abc_rounded,
        title: 'Word Builder',
        subtitle: 'Vocabulary game',
        color: Colors.pink,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const WordBuilderScreen())),
      ),
      FeatureTile(
        icon: Icons.calculate_rounded,
        title: 'Engineering Toolkit',
        subtitle: 'Solvers & converters',
        color: Colors.teal,
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: features,
            ),
          ),
          const SectionHeader('Subject-wise practice'),
          for (final s in subjects)
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(s),
              subtitle: Text('${questionsFor(goal.id, subject: s).length} questions with solutions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _start(
                  context, '$s Practice', questionsFor(goal.id, subject: s), QuizMode.practice),
            ),
          if (bookmarked.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: const Text('Bookmarked questions'),
              subtitle: Text('${bookmarked.length} saved for revision'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _start(context, 'Bookmarks', bookmarked, QuizMode.practice),
            ),
          const SectionHeader('Recent attempts'),
          if (progress.results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Your test history and analysis will appear here.'),
            ),
          for (final r in progress.results.take(10))
            ListTile(
              leading: CircleAvatar(child: Text('${(r.percent * 100).round()}')),
              title: Text(r.title),
              subtitle: Text(
                  '${r.correct}/${r.total} correct · ${r.seconds ~/ 60}m ${r.seconds % 60}s · ${MaterialLocalizations.of(context).formatShortDate(r.date)}'),
            ),
        ],
      ),
    );
  }
}
