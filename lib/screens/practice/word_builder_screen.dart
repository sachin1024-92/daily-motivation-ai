import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/study_content.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';

/// Timed vocabulary game: build as many words as you can from a set of letters.
class WordBuilderScreen extends ConsumerStatefulWidget {
  const WordBuilderScreen({super.key});

  @override
  ConsumerState<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends ConsumerState<WordBuilderScreen> {
  static const _roundSeconds = 90;

  int _round = DateTime.now().day % wordRounds.length;
  final List<int> _picked = [];
  final List<String> _found = [];
  int _score = 0;
  int _remaining = _roundSeconds;
  Timer? _timer;
  String? _message;

  WordRound get _current => wordRounds[_round];
  List<String> get _letters => _current.letters.split('');
  String get _word => _picked.map((i) => _letters[i]).join().toLowerCase();
  bool get _over => _remaining <= 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        ref.read(progressProvider.notifier).addXp(_score);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submit() {
    final w = _word;
    setState(() {
      if (w.length < 3) {
        _message = 'Words need at least 3 letters';
      } else if (_found.contains(w)) {
        _message = 'Already found "$w"';
      } else if (_current.words.contains(w)) {
        _found.insert(0, w);
        final points = w.length * 10 + (w.length >= 6 ? 30 : 0);
        _score += points;
        _message = '+$points  "$w"';
      } else {
        _message = '"$w" is not in this round\'s word list';
      }
      _picked.clear();
    });
  }

  void _nextRound() {
    setState(() {
      _round = (_round + 1) % wordRounds.length;
      _picked.clear();
      _found.clear();
      _score = 0;
      _remaining = _roundSeconds;
      _message = null;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Builder'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('⏱ ${_remaining.clamp(0, _roundSeconds)}s   ⭐ $_score'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Found ${_found.length} of ${_current.words.length} words',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 16),
            Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_word.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4)),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 22, child: Text(_message ?? '')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _letters.length; i++)
                  SizedBox(
                    width: 48,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: _over || _picked.contains(i)
                          ? null
                          : () => setState(() => _picked.add(i)),
                      child: Text(_letters[i], style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _picked.isEmpty ? null : () => setState(_picked.removeLast),
                    child: const Text('⌫ Undo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _picked.isEmpty ? null : () => setState(_picked.clear),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _over || _picked.isEmpty ? null : _submit,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
            if (_over) ...[
              const SizedBox(height: 16),
              Text('Time! You scored $_score (+$_score XP)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: _nextRound, child: const Text('Next round')),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final w in _found) Chip(label: Text(w))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
