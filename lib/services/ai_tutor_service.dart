import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:daily_motivation_ai/data/question_bank.dart';
import 'package:daily_motivation_ai/data/study_content.dart';

class ChatTurn {
  final bool fromUser;
  final String text;

  const ChatTurn({required this.fromUser, required this.text});
}

/// AI doubt solver.
///
/// Configure at build time — never hard-code keys in source:
///   flutter run --dart-define=AI_PROXY_URL=https://your-backend/api/tutor
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...   (dev only)
///
/// For a store release, use AI_PROXY_URL: a small backend that holds the key
/// and forwards the same JSON body to the Claude Messages API. A key compiled
/// into an APK can be extracted by anyone who downloads the app.
///
/// With nothing configured the tutor runs fully offline using the built-in
/// question bank and formula cards.
class AiTutorService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _proxyUrl = String.fromEnvironment('AI_PROXY_URL');
  static const _model = 'claude-opus-5-5';

  final http.Client _client;

  AiTutorService({http.Client? client}) : _client = client ?? http.Client();

  bool get isOnline => _apiKey.isNotEmpty || _proxyUrl.isNotEmpty;

  String _systemPrompt(String goalTitle) =>
      'You are a patient, expert tutor inside a learning app for Indian students. '
      'The student is preparing for: $goalTitle. '
      'Explain step by step, show the formula or rule used, then give the final answer clearly. '
      'Prefer NCERT-aligned explanations for school, JEE and NEET topics. '
      'Keep answers short enough to read on a phone. End with one quick follow-up practice question. '
      'If the question is not about studies or careers, gently steer back to learning.';

  Future<String> ask(String question, List<ChatTurn> history, String goalTitle) async {
    if (!isOnline) return offlineAnswer(question);

    final messages = <Map<String, String>>[
      for (final t in history.where((t) => t.text.trim().isNotEmpty))
        {'role': t.fromUser ? 'user' : 'assistant', 'content': t.text},
      {'role': 'user', 'content': question},
    ];
    // The API requires the conversation to start with a user turn.
    while (messages.isNotEmpty && messages.first['role'] != 'user') {
      messages.removeAt(0);
    }

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 16000,
      'system': _systemPrompt(goalTitle),
      'messages': messages,
      'fallbacks': 'default',
    });

    try {
      final response = await _client
          .post(
            Uri.parse(_proxyUrl.isNotEmpty
                ? _proxyUrl
                : 'https://api.anthropic.com/v1/messages'),
            headers: {
              'content-type': 'application/json',
              'anthropic-version': '2026-10-21',
              'anthropic-beta': 'server-side-fallback-2026-07-01',
              if (_proxyUrl.isEmpty) 'x-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(const Duration(minutes: 3));

      if (response.statusCode != 200) {
        return '${offlineAnswer(question)}\n\n(AI tutor unavailable — HTTP ${response.statusCode}. Showing an offline answer.)';
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['stop_reason'] == 'refusal') {
        return 'I can\'t help with that one. Try asking about a concept, a problem or a topic from your syllabus.';
      }
      final text = (data['content'] as List? ?? [])
          .whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String? ?? '')
          .join('\n')
          .trim();
      return text.isEmpty ? offlineAnswer(question) : text;
    } catch (_) {
      return '${offlineAnswer(question)}\n\n(You seem to be offline. Showing an offline answer.)';
    }
  }

  static Set<String> _tokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(' ')
      .where((w) => w.length > 2)
      .map((w) => w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w)
      .toSet();

  static const _studyPlan = '7-day revision plan\n\n'
      'Day 1 – List every chapter; mark each Strong / Medium / Weak.\n'
      'Day 2 – Weak chapter #1: notes + 30 practice questions.\n'
      'Day 3 – Weak chapter #2: notes + 30 practice questions.\n'
      'Day 4 – Formula & fact revision with Flashcards; one Speed Quiz.\n'
      'Day 5 – Medium chapters: solve previous-year-style questions.\n'
      'Day 6 – Full Mock Test under exam timing; analyse every mistake.\n'
      'Day 7 – Re-attempt wrong questions from Bookmarks; light revision, sleep early.\n\n'
      'Daily: 4 × 25-minute focus sessions, 10 minutes of flashcards, 1 Daily Quiz.';

  /// Keyword search over the local question bank and formula cards.
  static String offlineAnswer(String question) {
    final lower = question.toLowerCase();
    if (RegExp(r'\b(plan|schedule|timetable|routine)\b').hasMatch(lower)) {
      return _studyPlan;
    }
    final words = _tokens(question)..removeAll(_stopWords);
    if (words.isEmpty) {
      return 'Tell me the topic or paste the full question, e.g. "Explain Newton\'s second law" or "How do I find the roots of a quadratic?"';
    }

    int scoreOf(String haystack) => _tokens(haystack).intersection(words).length;

    final cards = [...flashcards]
      ..sort((a, b) => scoreOf('${b.front} ${b.back}').compareTo(scoreOf('${a.front} ${a.back}')));
    final qs = [...questionBank]
      ..sort((a, b) => scoreOf('${b.topic} ${b.text} ${b.explanation}')
          .compareTo(scoreOf('${a.topic} ${a.text} ${a.explanation}')));

    final buffer = StringBuffer();
    final bestCard = cards.first;
    final bestQ = qs.first;
    final cardHit = scoreOf('${bestCard.front} ${bestCard.back}') > 0;
    final qHit = scoreOf('${bestQ.topic} ${bestQ.text} ${bestQ.explanation}') > 0;

    if (!cardHit && !qHit) {
      return 'I couldn\'t find this in the offline library yet.\n\n'
          'Try this approach:\n'
          '1. Write down what is given and what is asked.\n'
          '2. Identify the chapter and the formula that links them.\n'
          '3. Substitute with units and simplify.\n\n'
          'Connect the online AI tutor (see README) for full step-by-step solutions to any question.';
    }
    if (cardHit) {
      buffer
        ..writeln('📌 ${bestCard.front}')
        ..writeln(bestCard.back)
        ..writeln();
    }
    if (qHit) {
      buffer
        ..writeln('🧠 Related concept (${bestQ.subject} · ${bestQ.topic})')
        ..writeln(bestQ.explanation)
        ..writeln()
        ..writeln('Try this: ${bestQ.text}')
        ..writeln(bestQ.options
            .asMap()
            .entries
            .map((e) => '  ${String.fromCharCode(65 + e.key)}) ${e.value}')
            .join('\n'));
    }
    return buffer.toString().trim();
  }

  static const _stopWords = {
    'what', 'which', 'explain', 'please', 'with', 'from', 'that', 'this', 'have',
    'does', 'how', 'why', 'when', 'where', 'there', 'their', 'about', 'into',
    'find', 'solve', 'give', 'tell', 'mean', 'difference', 'between', 'the',
    'and', 'for', 'are', 'can', 'you', 'make', 'example', 'simply', 'simple',
  };
}
