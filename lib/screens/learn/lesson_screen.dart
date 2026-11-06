import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/courses.dart';
import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/screens/doubts_screen.dart';
import 'package:daily_motivation_ai/screens/practice/quiz_screen.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final Chapter chapter;

  const LessonScreen({super.key, required this.lesson, required this.chapter});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  // Simulated player: replace with a real video player (e.g. video_player
  // package + your CDN/HLS URLs) when content is hosted.
  Timer? _timer;
  double _position = 0;
  bool _playing = false;
  double _speed = 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _timer?.cancel();
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          _position = (_position + 0.01 * _speed).clamp(0, 1);
          if (_position >= 1) {
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  List<Question> _relatedQuestions() {
    final keys = {
      widget.chapter.title.toLowerCase(),
      widget.lesson.title.toLowerCase(),
    };
    final matches = questionBank.where((q) {
      final t = q.topic.toLowerCase();
      return keys.any((k) => k.contains(t) || t.contains(k.split(' ').first));
    }).toList();
    if (matches.isNotEmpty) return matches;
    return questionBank.where((q) => q.subject == widget.chapter.subject).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final done = ref.watch(progressProvider).completedLessons.contains(lesson.id);
    final theme = Theme.of(context);
    final elapsed = (_position * lesson.minutes * 60).round();

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        children: [
          if (lesson.type == LessonType.video)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    Center(
                      child: IconButton(
                        iconSize: 64,
                        color: Colors.white,
                        icon: Icon(_playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded),
                        onPressed: _togglePlay,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Text(widget.chapter.subject,
                          style: const TextStyle(color: Colors.white70)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Text(
                              '${elapsed ~/ 60}:${(elapsed % 60).toString().padLeft(2, '0')} / ${lesson.minutes}:00',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _position,
                              onChanged: (v) => setState(() => _position = v),
                            ),
                          ),
                          PopupMenuButton<double>(
                            initialValue: _speed,
                            onSelected: (s) => setState(() => _speed = s),
                            itemBuilder: (_) => [
                              for (final s in [0.75, 1.0, 1.25, 1.5, 2.0])
                                PopupMenuItem(value: s, child: Text('${s}x')),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${_speed}x',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${widget.chapter.title} · ${lesson.minutes} min'),
                const SizedBox(height: 16),
                Text('Notes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(lesson.notes,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.psychology_alt_rounded),
                        label: const Text('Ask a doubt'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoubtsScreen(
                              initialQuestion: 'Explain "${lesson.title}" simply with an example.',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text('Practice'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              title: '${widget.chapter.title} Practice',
                              questions: _relatedQuestions(),
                              mode: QuizMode.practice,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(done ? 'Completed' : 'Mark as complete (+20 XP)'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: done ? Colors.green : null,
                  ),
                  onPressed: () =>
                      ref.read(progressProvider.notifier).toggleLesson(lesson.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
