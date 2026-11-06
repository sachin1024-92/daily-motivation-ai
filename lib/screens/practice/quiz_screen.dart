import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/models/quiz_result.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/practice/result_screen.dart';

enum QuizMode {
  /// Untimed, instant feedback and explanation after each answer.
  practice,

  /// Fixed seconds per question, auto-advances, rewards speed.
  speed,

  /// Full exam simulation: overall timer, +4 / −1 marking, review palette.
  mock,
}

List<Question> pickQuestions(List<Question> pool, int count, {Random? random}) {
  final list = [...pool]..shuffle(random ?? Random());
  return list.take(count).toList();
}

/// Deterministic per day and goal, so everyone gets the same daily quiz.
List<Question> dailyQuestions(String goalId, DateTime day) {
  final seed = day.year * 10000 + day.month * 100 + day.day + goalId.hashCode;
  return pickQuestions(questionsFor(goalId), 5, random: Random(seed));
}

class QuizScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Question> questions;
  final QuizMode mode;
  final int secondsPerQuestion;
  final double marksCorrect;
  final double marksWrong;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.mode,
    this.secondsPerQuestion = 20,
    this.marksCorrect = 4,
    this.marksWrong = 1,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final List<int?> _answers = List.filled(widget.questions.length, null);
  late final List<bool> _marked = List.filled(widget.questions.length, false);
  int _index = 0;
  bool _revealed = false;
  Timer? _timer;
  late int _remaining;
  final _stopwatch = Stopwatch()..start();
  bool _finished = false;

  bool get _isMock => widget.mode == QuizMode.mock;
  bool get _isSpeed => widget.mode == QuizMode.speed;

  @override
  void initState() {
    super.initState();
    _remaining = _isMock
        ? widget.questions.length * 60 // 1 minute per question in mock tests
        : widget.secondsPerQuestion;
    if (_isMock || _isSpeed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _finished) return;
    setState(() => _remaining--);
    if (_remaining > 0) return;
    if (_isMock) {
      _submit();
    } else if (_isSpeed && !_revealed) {
      _reveal();
    }
  }

  void _select(int option) {
    if (_revealed) return;
    setState(() => _answers[_index] = option);
    if (!_isMock) _reveal();
  }

  void _reveal() {
    setState(() => _revealed = true);
    if (_isSpeed) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && !_finished) _next();
      });
    }
  }

  void _next() {
    if (_index >= widget.questions.length - 1) {
      _submit();
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      if (_isSpeed) _remaining = widget.secondsPerQuestion;
    });
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _answers.where((a) => a == null).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit test?'),
        content: Text(unanswered == 0
            ? 'You have answered all questions.'
            : '$unanswered question(s) are unanswered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok == true) _submit();
  }

  void _submit() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _stopwatch.stop();

    var correct = 0, wrong = 0;
    final topics = <String, List<int>>{};
    for (var i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final t = topics.putIfAbsent('${q.subject} · ${q.topic}', () => [0, 0]);
      t[1]++;
      final a = _answers[i];
      if (a == null) continue;
      if (a == q.answer) {
        correct++;
        t[0]++;
      } else {
        wrong++;
      }
    }
    final negative = _isMock ? widget.marksWrong : 0.0;
    final result = QuizResult(
      title: widget.title,
      mode: widget.mode.name,
      date: DateTime.now(),
      total: widget.questions.length,
      correct: correct,
      wrong: wrong,
      score: correct * widget.marksCorrect - wrong * negative,
      maxScore: widget.questions.length * widget.marksCorrect,
      seconds: _stopwatch.elapsed.inSeconds,
      topics: topics.map((k, v) => MapEntry(k, TopicScore(v[0], v[1]))),
    );
    ref.read(progressProvider.notifier).recordResult(result);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          questions: widget.questions,
          answers: List.of(_answers),
        ),
      ),
    );
  }

  String _clock(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No questions available for this selection yet.')),
      );
    }
    final q = widget.questions[_index];
    final theme = Theme.of(context);
    final bookmarked = ref.watch(progressProvider).bookmarkedQuestions.contains(q.id);
    final total = widget.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quit?'),
            content: const Text('Your progress in this attempt will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quit')),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          _finished = true;
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            if (_isMock || _isSpeed)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(_clock(max(_remaining, 0))),
                  backgroundColor: _remaining <= (_isMock ? 60 : 5)
                      ? theme.colorScheme.errorContainer
                      : null,
                ),
              ),
            IconButton(
              tooltip: 'Bookmark',
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => ref.read(progressProvider.notifier).toggleBookmark(q.id),
            ),
            if (_isMock)
              TextButton(onPressed: _confirmSubmit, child: const Text('Submit')),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / total),
            if (_isSpeed)
              LinearProgressIndicator(
                value: max(_remaining, 0) / widget.secondsPerQuestion,
                color: Colors.orange,
                backgroundColor: Colors.transparent,
                minHeight: 3,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Text('Q${_index + 1} of $total',
                          style: theme.textTheme.labelLarge),
                      const Spacer(),
                      Text('${q.subject} · ${q.topic}', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(q.text,
                      style: theme.textTheme.titleMedium?.copyWith(height: 1.4)),
                  const SizedBox(height: 16),
                  for (var i = 0; i < q.options.length; i++) _option(q, i, theme),
                  if (_revealed && !_isMock) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('💡 ${q.explanation}'),
                      ),
                    ),
                  ],
                  if (_isMock) ...[
                    const SizedBox(height: 16),
                    Text('Question palette', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < total; i++)
                          InkWell(
                            onTap: () => setState(() => _index = i),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: _marked[i]
                                  ? Colors.purple
                                  : _answers[i] != null
                                      ? Colors.green
                                      : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: (_marked[i] || _answers[i] != null)
                                  ? Colors.white
                                  : null,
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontWeight:
                                          i == _index ? FontWeight.w900 : FontWeight.normal)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Green = answered · Purple = marked for review · +4 / −1 marking',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _isMock ? _mockControls(total) : _practiceControls(total),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(Question q, int i, ThemeData theme) {
    final selected = _answers[_index] == i;
    Color? bg;
    Color? border;
    if (_revealed && !_isMock) {
      if (i == q.answer) {
        bg = Colors.green.withValues(alpha: 0.15);
        border = Colors.green;
      } else if (selected) {
        bg = Colors.red.withValues(alpha: 0.15);
        border = Colors.red;
      }
    } else if (selected) {
      bg = theme.colorScheme.primaryContainer;
      border = theme.colorScheme.primary;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg ?? theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border ?? Colors.transparent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _select(i),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(q.options[i])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _practiceControls(int total) {
    if (_isSpeed) {
      return Text(_revealed ? 'Next question…' : 'Answer before the timer runs out!',
          textAlign: TextAlign.center);
    }
    return FilledButton(
      onPressed: _revealed ? _next : null,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: Text(_index == total - 1 ? 'See result' : 'Next'),
    );
  }

  Widget _mockControls(int total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _marked[_index] = !_marked[_index]),
            child: Text(_marked[_index] ? 'Unmark' : 'Mark for review'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _answers[_index] == null
                ? null
                : () => setState(() => _answers[_index] = null),
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: _index == total - 1 ? _confirmSubmit : _next,
            child: Text(_index == total - 1 ? 'Submit' : 'Save & next'),
          ),
        ),
      ],
    );
  }
}
