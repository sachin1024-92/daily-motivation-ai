import 'package:flutter/material.dart';

/// A learning goal the student is preparing for. Everything in the app
/// (courses, quizzes, flashcards, live classes) is filtered by this.
class Goal {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> subjects;

  const Goal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.subjects,
  });
}

const List<Goal> goals = [
  Goal(
    id: 'jee',
    title: 'JEE (Engineering)',
    subtitle: 'Main + Advanced · Class 11-12',
    icon: Icons.engineering_rounded,
    color: Colors.indigo,
    subjects: ['Physics', 'Chemistry', 'Mathematics'],
  ),
  Goal(
    id: 'neet',
    title: 'NEET (Medical)',
    subtitle: 'NCERT-first · Class 11-12',
    icon: Icons.biotech_rounded,
    color: Colors.teal,
    subjects: ['Physics', 'Chemistry', 'Biology'],
  ),
  Goal(
    id: 'gate',
    title: 'GATE & B.Tech',
    subtitle: 'Core engineering + CS',
    icon: Icons.memory_rounded,
    color: Colors.deepOrange,
    subjects: ['Computer Science', 'Electrical', 'Mathematics'],
  ),
  Goal(
    id: 'govt',
    title: 'Govt Jobs (SSC / Bank)',
    subtitle: 'Quant · Reasoning · English · GK',
    icon: Icons.account_balance_rounded,
    color: Colors.brown,
    subjects: ['Quant', 'Reasoning', 'English', 'General Awareness'],
  ),
  Goal(
    id: 'school',
    title: 'School (Class 6-10)',
    subtitle: 'Concepts, homework help, boards',
    icon: Icons.school_rounded,
    color: Colors.pink,
    subjects: ['Mathematics', 'Science', 'English'],
  ),
  Goal(
    id: 'career',
    title: 'Upskill & Career',
    subtitle: 'Data, AI, coding, product',
    icon: Icons.work_rounded,
    color: Colors.green,
    subjects: ['Programming', 'Data Science', 'AI & ML'],
  ),
];

Goal goalById(String? id) =>
    goals.firstWhere((g) => g.id == id, orElse: () => goals.first);
