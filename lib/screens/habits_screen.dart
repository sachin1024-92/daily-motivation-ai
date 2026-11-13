import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/providers/habits_provider.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final habitsNotifier = ref.read(habitsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('My Habits')),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          return Dismissible(
            key: ValueKey(habit.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red.shade400,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => habitsNotifier.removeHabit(habit.id),
            child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Checkbox(
                value: habit.completedToday,
                onChanged: (_) => habitsNotifier.toggleHabit(habit.id),
              ),
              title: Text(habit.title),
              subtitle: Text(habit.description),
              trailing: Chip(
                label: Text('${habit.streak} 🔥'),
                backgroundColor: habit.streak > 0 ? Colors.orange.shade100 : null,
              ),
            ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, habitsNotifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, HabitsNotifier notifier) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Habit title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                notifier.addHabit(titleController.text.trim(), descController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
