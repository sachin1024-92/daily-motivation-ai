import 'package:http/http.dart' as http;
import 'dart:convert';

class GrokService {
  // Pass your key at build time, never commit it:
  //   flutter run --dart-define=GROK_API_KEY=xai-...
  static const String _apiKey = String.fromEnvironment('GROK_API_KEY');
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';

  bool get isLive => _apiKey.isNotEmpty;

  Future<String> getMotivationResponse(String prompt) async {
    if (!isLive) return _getSimulatedResponse(prompt);
    final reply = await _complete(
      system: 'You are Orbit AI, a supportive, concise daily motivation coach living inside a social app. '
          'Keep responses encouraging, actionable, and under 150 words.',
      prompt: prompt,
      maxTokens: 200,
    );
    return reply ?? _getSimulatedResponse(prompt);
  }

  /// A short, trendy caption for the composer's "Magic caption" button.
  Future<String> suggestCaption(String draft) async {
    if (isLive) {
      final reply = await _complete(
        system: 'You write short, trendy social media captions: max 20 words, 1-2 emojis, no hashtags spam.',
        prompt: draft.trim().isEmpty ? 'Write a caption for a feel-good post.' : 'Improve this caption: $draft',
        maxTokens: 60,
      );
      if (reply != null) return reply.trim();
    }
    return _simulatedCaption(draft);
  }

  /// Quick one-tap replies for the message the user is answering.
  List<String> smartReplies(String incoming) {
    final lower = incoming.toLowerCase();
    if (lower.contains('?')) {
      if (lower.contains('weekend') || lower.contains('trip') || lower.contains('saturday')) {
        return ['I\'m in! 🙌', 'What time?', 'Can\'t this time 😢'];
      }
      return ['Yes! 🙌', 'Not sure yet 🤔', 'Tell me more'];
    }
    if (lower.contains('thank')) return ['Anytime! 😊', 'Of course 🙏', '❤️'];
    if (lower.contains('see this') || lower.contains('look')) return ['Whoa 😮', 'Saving this 🔖', 'Haha love it'];
    if (lower.contains('😂') || lower.contains('haha')) return ['😂😂', 'Stop 💀', 'Facts'];
    return ['Love this ❤️', 'Haha 😂', 'Sounds good 👍'];
  }

  Future<String?> _complete({required String system, required String prompt, required int maxTokens}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'grok-2-latest', // or latest available
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getSimulatedResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('habit') || lower.contains('streak')) {
      return 'Amazing work on your habits! Small daily actions compound into massive results. Keep showing up — you\'re building something great.';
    } else if (lower.contains('focus') || lower.contains('timer')) {
      return 'Deep focus is your superpower. One focused session at a time. You\'re making progress even when it feels slow.';
    } else if (lower.contains('plan') || lower.contains('today')) {
      return 'Here\'s a simple plan: 1) Pick ONE must-win task and do it first in a 25-min focus block. 2) Move your body for 10 minutes. 3) Send one message to someone you appreciate. Small wins, big day. 🚀';
    } else if (lower.contains('caption') || lower.contains('post')) {
      return 'Try one of these: "Small steps, big orbit 🌍" · "Plot twist: I actually did the thing ✨" · "Main character energy, minimal effort 😌"';
    } else {
      return 'Today is a new opportunity to move closer to your goals. You are capable, resilient, and worthy of success. Let\'s make it count!';
    }
  }

  String _simulatedCaption(String draft) {
    const captions = [
      'Small steps, big orbit 🌍✨',
      'Plot twist: I actually did the thing 🙌',
      'Collecting moments, not things 📸',
      'Main character energy, minimal effort 😌',
      'Today\'s vibe: progress over perfection 🌱',
    ];
    final base = captions[draft.length % captions.length];
    final trimmed = draft.trim();
    return trimmed.isEmpty ? base : '$trimmed — $base';
  }
}
