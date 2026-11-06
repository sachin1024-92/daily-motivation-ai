import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/goals.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/services/ai_tutor_service.dart';

final aiTutorProvider = Provider<AiTutorService>((ref) => AiTutorService());

class DoubtsScreen extends ConsumerStatefulWidget {
  final String? initialQuestion;

  const DoubtsScreen({super.key, this.initialQuestion});

  @override
  ConsumerState<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends ConsumerState<DoubtsScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatTurn> _turns = [];
  bool _thinking = false;

  static const _suggestions = [
    'Explain Newton\'s second law with an example',
    'How do I find the roots of a quadratic?',
    'What is the mole concept?',
    'Make me a 7-day revision plan',
    'Difference between overfitting and underfitting',
    'Shortcut for successive percentage change',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialQuestion!));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _thinking) return;
    final history = List<ChatTurn>.of(_turns);
    setState(() {
      _turns.add(ChatTurn(fromUser: true, text: text));
      _thinking = true;
    });
    _controller.clear();
    _scrollToEnd();

    final goal = goalById(ref.read(profileProvider).goalId);
    final answer = await ref.read(aiTutorProvider).ask(text, history, goal.title);
    ref.read(progressProvider.notifier).countDoubt();
    if (!mounted) return;
    setState(() {
      _turns.add(ChatTurn(fromUser: false, text: answer));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = ref.watch(aiTutorProvider).isOnline;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doubt Solver'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(online ? Icons.cloud_done : Icons.offline_bolt, size: 16),
              label: Text(online ? 'Claude AI' : 'Offline tutor'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _turns.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Icon(Icons.psychology_alt_rounded,
                          size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text('Stuck on something? Ask anything from your syllabus.',
                          textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final s in _suggestions)
                            ActionChip(label: Text(s), onPressed: () => _send(s)),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _turns.length + (_thinking ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _turns.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      }
                      final t = _turns[i];
                      return Align(
                        alignment: t.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.85),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.fromUser
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(
                            t.text,
                            style: TextStyle(
                              color: t.fromUser ? theme.colorScheme.onPrimary : null,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type or paste your question…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _thinking ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
