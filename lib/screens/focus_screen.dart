import 'package:flutter/material.dart';
import 'dart:async';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _seconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _showSessionComplete();
      }
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 25 * 60;
      _isRunning = false;
    });
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Session Complete!'),
        content: const Text('Great focus! Take a short break or start another session.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  String get _formattedTime {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 20),
            Text(
              _isRunning ? 'Stay focused...' : 'Ready to begin?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start 25 min'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Pomodoro Technique • 25 min focus + 5 min break'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
