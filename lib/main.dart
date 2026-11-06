import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_motivation_ai/providers/app_state.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'package:daily_motivation_ai/screens/doubts_screen.dart';
import 'package:daily_motivation_ai/screens/home_screen.dart';
import 'package:daily_motivation_ai/screens/learn/learn_screen.dart';
import 'package:daily_motivation_ai/screens/onboarding_screen.dart';
import 'package:daily_motivation_ai/screens/practice/practice_screen.dart';
import 'package:daily_motivation_ai/screens/profile_screen.dart';

void main() {
  runApp(const ProviderScope(child: PrepVerseApp()));
}

const appName = 'PrepVerse AI';

class PrepVerseApp extends ConsumerWidget {
  const PrepVerseApp({super.key});

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: brightness,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: appName,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ref.watch(themeProvider),
      debugShowCheckedModeBanner: false,
      home: const RootGate(),
    );
  }
}

/// Shows onboarding on first launch, then the main app.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (!profile.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!profile.onboarded) return const OnboardingScreen();
    return const MainNavigation();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  void goTo(int index) => setState(() => _index = index);

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(
        icon: Icon(Icons.play_circle_outline),
        selectedIcon: Icon(Icons.play_circle_rounded),
        label: 'Learn'),
    NavigationDestination(
        icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: 'Practice'),
    NavigationDestination(
        icon: Icon(Icons.psychology_alt_outlined),
        selectedIcon: Icon(Icons.psychology_alt_rounded),
        label: 'Doubts'),
    NavigationDestination(
        icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigate: goTo),
          const LearnScreen(),
          const PracticeScreen(),
          const DoubtsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: _destinations,
      ),
    );
  }
}
