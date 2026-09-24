import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/shell.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OrbitApp(),
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
