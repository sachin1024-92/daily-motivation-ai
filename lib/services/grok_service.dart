import 'package:http/http.dart' as http;
import 'dart:convert';

class GrokService {
  // TODO: Replace with your actual Grok/xAI API key
  static const String _apiKey = 'YOUR_GROK_API_KEY_HERE';
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';

  Future<String> getMotivationResponse(String prompt) async {
    if (_apiKey == 'YOUR_GROK_API_KEY_HERE') {
      return _getSimulatedResponse(prompt);
    }

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
            {'role': 'system', 'content': 'You are a supportive, concise daily motivation coach. Keep responses encouraging, actionable, and under 150 words.'},
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Stay strong today!';
      } else {
        return 'Sorry, I could not reach Grok right now. Here\'s some motivation: You\'ve got this!';
      }
    } catch (e) {
      return _getSimulatedResponse(prompt);
    }
  }

  String _getSimulatedResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('habit') || lower.contains('streak')) {
      return 'Amazing work on your habits! Small daily actions compound into massive results. Keep showing up — you\'re building something great.';
    } else if (lower.contains('focus') || lower.contains('timer')) {
      return 'Deep focus is your superpower. One focused session at a time. You\'re making progress even when it feels slow.';
    } else {
      return 'Today is a new opportunity to move closer to your goals. You are capable, resilient, and worthy of success. Let\'s make it count!';
    }
  }
}
