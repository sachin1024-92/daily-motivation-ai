import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/app/links.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/providers/habits_provider.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/screens/wellbeing/wellbeing_screen.dart';
import 'package:daily_motivation_ai/services/external_share.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your data?'),
        content: const Text(
          'This erases your profile, linked accounts, habits and settings from this device. '
          'An Orbit Plus subscription stays with your Google account; cancel it in Google Play.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    ref
      ..invalidate(profileProvider)
      ..invalidate(habitsProvider)
      ..invalidate(themeProvider)
      ..invalidate(aiQuotaProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your data on this device was deleted')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(isPlusProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: const Text('Orbit Plus'),
            subtitle: Text(plus ? 'Active, thanks for your support' : 'No ads, unlimited AI, featured services'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openPlus(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.spa_outlined),
            title: const Text('Wellbeing'),
            subtitle: const Text('Habits, focus timer and your AI coach'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellbeingScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: () => ExternalShare.open(context, OrbitLinks.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: const Text('Terms of service'),
            onTap: () => ExternalShare.open(context, OrbitLinks.terms),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Contact support'),
            subtitle: const SelectableText(OrbitLinks.supportEmail),
            onTap: () => ExternalShare.open(
              context,
              Uri(scheme: 'mailto', path: OrbitLinks.supportEmail, query: 'subject=Orbit support'),
            ),
          ),
          const Divider(),
          ListTile(
            key: const ValueKey('delete-data'),
            leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            title: Text('Delete my data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Erase everything Orbit stores on this device'),
            onTap: () => _deleteData(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Orbit is in preview. The creators, posts, channels and chat replies you see are sample content. '
              'What you create stays on this device.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
