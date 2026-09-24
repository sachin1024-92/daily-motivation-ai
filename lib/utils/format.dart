import 'package:intl/intl.dart';

/// Short relative time, e.g. `now`, `5m`, `3h`, `2d`, `Mar 4`.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(time);
}

/// Wall-clock time for chat bubbles.
String clockTime(DateTime time) => DateFormat('HH:mm').format(time);

/// Label for chat day separators.
String dayLabel(DateTime time, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(time);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, MMM d').format(time);
}

/// 999, 1.2K, 3.4M.
String compactCount(int n) => n < 1000 ? '$n' : NumberFormat.compact().format(n);

/// 4:05 or 1:02:03.
String formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
