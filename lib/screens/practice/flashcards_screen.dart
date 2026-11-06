import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/study_content.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';

/// Leitner-box flashcards: cards you know move up a box and come back less
/// often; cards you miss drop to box 0.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  late List<Flashcard> _queue;
  bool _showBack = false;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    final goalId = ref.read(profileProvider).goalId;
    final boxes = ref.read(progressProvider).cardBoxes;
    _queue = flashcardsFor(goalId)
      ..sort((a, b) => (boxes[a.id] ?? 0).compareTo(boxes[b.id] ?? 0));
  }

  void _answer(bool knewIt) {
    final card = _queue.first;
    ref.read(progressProvider.notifier).reviewCard(card.id, knewIt: knewIt);
    setState(() {
      _queue.removeAt(0);
      // Missed cards come back later in this session.
      if (!knewIt) _queue.insert(_queue.length < 3 ? _queue.length : 3, card);
      _showBack = false;
      _reviewed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxes = ref.watch(progressProvider).cardBoxes;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: _queue.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text('Session complete — $_reviewed reviews',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => Navigator.pop(context), child: const Text('Done')),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${_queue.length} cards left · Box ${(boxes[_queue.first.id] ?? 0) + 1} of 5',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showBack = !_showBack),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Card(
                          key: ValueKey('${_queue.first.id}-$_showBack'),
                          color: _showBack
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.primaryContainer,
                          child: SizedBox.expand(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  _showBack ? _queue.first.back : _queue.first.front,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_showBack)
                    FilledButton.tonal(
                      onPressed: () => setState(() => _showBack = true),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Show answer'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _answer(false),
                            icon: const Icon(Icons.replay),
                            label: const Text('Again'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _answer(true),
                            icon: const Icon(Icons.check),
                            label: const Text('Got it'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
