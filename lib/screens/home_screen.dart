import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/models/quote.dart';
import 'package:daily_motivation_ai/providers/theme_provider.dart';
import 'dart:math';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Quote _dailyQuote;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _dailyQuote = defaultQuotes[random.nextInt(defaultQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning, Sachin!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Quote Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.format_quote, size: 40, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    Text(
                      _dailyQuote.text,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${_dailyQuote.author}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Today\'s Focus', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.flag_rounded, color: Colors.orange),
                title: Text('Complete 1 deep work session'),
                subtitle: Text('25-minute focused block on your most important task'),
              ),
            ),
            const SizedBox(height: 24),

            Text('Quick Stats', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: const [
                          Text('12', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          Text('Day Streak'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                    child: Column(
                        children: const [
                          Text('87%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          Text('Habit Completion'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
