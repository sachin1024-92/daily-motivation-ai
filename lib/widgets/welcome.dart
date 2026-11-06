import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

const _seenKey = 'welcome_seen';

/// Shows the one-time welcome sheet on first launch. It tells people up
/// front that the community they see is sample content.
Future<void> showWelcomeIfNeeded(BuildContext context) async {
  bool seen;
  try {
    final prefs = await SharedPreferences.getInstance();
    seen = prefs.getBool(_seenKey) ?? false;
  } catch (_) {
    seen = true;
  }
  if (seen || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (context) => const _WelcomeSheet(),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  } catch (_) {}
}

class _WelcomeSheet extends StatelessWidget {
  const _WelcomeSheet();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget point(IconData icon, String title, String body) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(body),
        );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: OrbitLogo(size: 30)),
            const SizedBox(height: 12),
            const Text(
              'Posts, stories, reels, video, chats and services in one app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            point(Icons.science_outlined, 'You\'re in the preview',
                'The creators, posts, channels and chat replies here are sample content so you can try everything.'),
            point(Icons.phone_android_rounded, 'Your stuff stays on this device',
                'Your profile and habits are saved here. In the preview, your posts and chats reset when the app restarts.'),
            point(Icons.auto_awesome_rounded, 'Meet Orbit AI', 'Your coach is pinned in Chats. Ask for motivation, a plan or captions.'),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('welcome-start'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Start exploring'),
            ),
            const SizedBox(height: 4),
            Text(
              'You can review the privacy policy any time in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
