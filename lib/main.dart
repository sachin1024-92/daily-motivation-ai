import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/screens/home_screen.dart';
import 'package:daily_motivation_ai/screens/habits_screen.dart';
import 'package:daily_motivation_ai/screens/focus_screen.dart';
import 'package:daily_motivation_ai/screens/ai_chat_screen.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DailyMotivationApp(),
    ),
  );
}

class DailyMotivationApp extends ConsumerWidget {
  const DailyMotivationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Daily Motivation AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HabitsScreen(),
    FocusScreen(),
    AIChatScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.checklist_rounded),
      label: 'Habits',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.timer_rounded),
      label: 'Focus',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_rounded),
      label: 'AI Chat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
