import 'package:flutter/material.dart';

import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/models/quiz_result.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class ResultScreen extends StatelessWidget {
  final QuizResult result;
  final List<Question> questions;
  final List<int?> answers;

  const ResultScreen({
    super.key,
    required this.result,
    required this.questions,
    required this.answers,
  });

  String get _verdict {
    final p = result.percent;
    if (p >= 0.9) return 'Outstanding! Topper territory 🏆';
    if (p >= 0.7) return 'Great work — keep the momentum 🚀';
    if (p >= 0.4) return 'Good effort — review the weak topics below 💪';
    return 'Every mistake is a lesson. Revise and retry 📚';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topics = result.topics.entries.toList()
      ..sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    final weak = topics.where((t) => t.value.accuracy < 0.6).map((t) => t.key).toList();
    final avgSec = result.total == 0 ? 0 : result.seconds ~/ result.total;

    return Scaffold(
      appBar: AppBar(title: Text('${result.title} · Result')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 110,
                      width: 110,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: result.percent,
                            strokeWidth: 10,
                            backgroundColor: theme.colorScheme.surface,
                          ),
                          Center(
                            child: Text('${(result.percent * 100).round()}%',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Score ${result.score.toStringAsFixed(result.score % 1 == 0 ? 0 : 1)} / ${result.maxScore.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(_verdict, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: StatTile(
                        icon: Icons.check_circle,
                        value: '${result.correct}',
                        label: 'Correct',
                        color: Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        icon: Icons.cancel,
                        value: '${result.wrong}',
                        label: 'Wrong',
                        color: Colors.red)),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        icon: Icons.remove_circle_outline,
                        value: '${result.skipped}',
                        label: 'Skipped')),
                const SizedBox(width: 8),
                Expanded(
                    child: StatTile(
                        icon: Icons.speed, value: '${avgSec}s', label: 'Avg / Q')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Accuracy (of attempted): ${(result.accuracy * 100).round()}%'),
          ),
          const SectionHeader('Topic-wise analysis'),
          for (final t in topics)
            ListTile(
              dense: true,
              title: Text(t.key),
              subtitle: LinearProgressIndicator(
                value: t.value.accuracy,
                color: t.value.accuracy >= 0.6 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              trailing: Text('${t.value.correct}/${t.value.total}'),
            ),
          if (weak.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: const Text('Focus next on'),
                  subtitle: Text(weak.join(', ')),
                ),
              ),
            ),
          const SectionHeader('Review answers'),
          for (var i = 0; i < questions.length; i++) _review(context, i),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context, int i) {
    final q = questions[i];
    final a = answers[i];
    final correct = a == q.answer;
    final icon = a == null
        ? const Icon(Icons.remove_circle_outline, color: Colors.grey)
        : Icon(correct ? Icons.check_circle : Icons.cancel,
            color: correct ? Colors.green : Colors.red);
    return ExpansionTile(
      leading: icon,
      title: Text('Q${i + 1}. ${q.text}', maxLines: 2, overflow: TextOverflow.ellipsis),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.text),
        const SizedBox(height: 6),
        Text('Your answer: ${a == null ? 'Not attempted' : q.options[a]}'),
        Text('Correct answer: ${q.options[q.answer]}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('💡 ${q.explanation}'),
      ],
    );
  }
}
