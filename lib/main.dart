import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/shell.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/services/ads_service.dart';
import 'package:daily_motivation_ai/services/billing_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  runApp(
    ProviderScope(
      overrides: [
        // Google Play Billing and AdMob exist only in the Android app.
        if (android) plusStoreProvider.overrideWithValue(PlayPlusStore()),
        if (android) adsConfigProvider.overrideWithValue(AdsService.start()),
      ],
      child: const OrbitApp(),
    ),
  );
}

class OrbitApp extends ConsumerWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Orbit',
      theme: OrbitTheme.light(),
      darkTheme: OrbitTheme.dark(),
      themeMode: themeMode,
      home: const OrbitShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
