import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/data/study_content.dart';
import 'package:daily_motivation_ai/providers/app_state.dart';

/// Live classroom UI: stage, live chat, raise hand and in-class polls.
///
/// This build simulates the class locally. To go live, plug the stage into a
/// streaming SDK (e.g. WebRTC / LL-HLS) and the chat into a realtime backend.
class LiveClassScreen extends ConsumerStatefulWidget {
  final LiveClass liveClass;

  const LiveClassScreen({super.key, required this.liveClass});

  @override
  ConsumerState<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _ChatMsg {
  final String who;
  final String text;
  final bool mine;

  const _ChatMsg(this.who, this.text, {this.mine = false});
}

class _LiveClassScreenState extends ConsumerState<LiveClassScreen> {
  final _rng = Random();
  final _input = TextEditingController();
  final List<_ChatMsg> _chat = [];
  Timer? _chatTimer;
  Timer? _pollTimer;
  Question? _poll;
  int? _pollAnswer;
  bool _handRaised = false;
  late int _viewers = 800 + _rng.nextInt(4000);

  static const _peerNames = ['Aarav', 'Diya', 'Kabir', 'Ananya', 'Ishaan', 'Meera', 'Rohan', 'Sara'];
  static const _peerLines = [
    'Sir, please repeat the last step 🙏',
    'Got it!',
    'Is this important for the exam?',
    'Can you share the notes PDF?',
    'Option B?',
    'Wow, that trick is amazing 🔥',
    'Present 🙋',
    'Please solve one more example',
  ];

  @override
  void initState() {
    super.initState();
    _chat.add(_ChatMsg(widget.liveClass.teacher,
        'Welcome everyone! Today: ${widget.liveClass.title}. Ask questions any time.'));
    _chatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _viewers += _rng.nextInt(40) - 15;
        _chat.add(_ChatMsg(_peerNames[_rng.nextInt(_peerNames.length)],
            _peerLines[_rng.nextInt(_peerLines.length)]));
        if (_chat.length > 60) _chat.removeAt(0);
      });
    });
    _pollTimer = Timer(const Duration(seconds: 10), _launchPoll);
  }

  void _launchPoll() {
    if (!mounted) return;
    final pool = questionBank.where((q) => q.subject == widget.liveClass.subject).toList();
    final source = pool.isEmpty ? questionBank : pool;
    setState(() {
      _poll = source[_rng.nextInt(source.length)];
      _pollAnswer = null;
    });
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _pollTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _chat.add(_ChatMsg(ref.read(profileProvider).name, text, mine: true)));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.liveClass.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor: Colors.red,
              labelStyle: const TextStyle(color: Colors.white),
              label: Text('LIVE · $_viewers'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.co_present_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 8),
                  Text(widget.liveClass.teacher, style: const TextStyle(color: Colors.white)),
                  Text(widget.liveClass.subject, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
          if (_poll != null)
            Card(
              margin: const EdgeInsets.all(8),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📊 Live poll', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _poll = null),
                        ),
                      ],
                    ),
                    Text(_poll!.text),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _poll!.options.length; i++)
                          ChoiceChip(
                            label: Text(_poll!.options[i]),
                            selected: _pollAnswer == i,
                            selectedColor: _pollAnswer == null
                                ? null
                                : (i == _poll!.answer ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.35),
                            onSelected: _pollAnswer != null
                                ? null
                                : (_) {
                                    setState(() => _pollAnswer = i);
                                    if (i == _poll!.answer) {
                                      ref.read(progressProvider.notifier).addXp(10);
                                    }
                                  },
                          ),
                      ],
                    ),
                    if (_pollAnswer != null) ...[
                      const SizedBox(height: 6),
                      Text(_pollAnswer == _poll!.answer
                          ? '✅ Correct! +10 XP'
                          : '❌ Answer: ${_poll!.options[_poll!.answer]}'),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _chat.length,
              itemBuilder: (_, i) {
                final m = _chat[_chat.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '${m.who}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: m.mine ? theme.colorScheme.primary : null,
                          ),
                        ),
                        TextSpan(text: m.text),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Raise hand',
                    icon: Icon(_handRaised ? Icons.back_hand : Icons.back_hand_outlined,
                        color: _handRaised ? Colors.amber : null),
                    onPressed: () {
                      setState(() => _handRaised = !_handRaised);
                      if (_handRaised) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Hand raised — the teacher will call on you')));
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Say something…',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send_rounded), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
