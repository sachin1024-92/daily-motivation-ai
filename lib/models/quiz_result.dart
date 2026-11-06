class TopicScore {
  final int correct;
  final int total;

  const TopicScore(this.correct, this.total);

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {'c': correct, 't': total};

  factory TopicScore.fromJson(Map<String, dynamic> j) =>
      TopicScore(j['c'] as int? ?? 0, j['t'] as int? ?? 0);
}

class QuizResult {
  final String title;
  final String mode;
  final DateTime date;
  final int total;
  final int correct;
  final int wrong;
  final double score;
  final double maxScore;
  final int seconds;
  final Map<String, TopicScore> topics;

  const QuizResult({
    required this.title,
    required this.mode,
    required this.date,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.score,
    required this.maxScore,
    required this.seconds,
    required this.topics,
  });

  int get skipped => total - correct - wrong;

  double get accuracy => (correct + wrong) == 0 ? 0 : correct / (correct + wrong);

  double get percent => maxScore == 0 ? 0 : (score / maxScore).clamp(0, 1);

  Map<String, dynamic> toJson() => {
        'title': title,
        'mode': mode,
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'wrong': wrong,
        'score': score,
        'maxScore': maxScore,
        'seconds': seconds,
        'topics': topics.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        title: j['title'] as String? ?? 'Quiz',
        mode: j['mode'] as String? ?? 'practice',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        total: j['total'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        wrong: j['wrong'] as int? ?? 0,
        score: (j['score'] as num? ?? 0).toDouble(),
        maxScore: (j['maxScore'] as num? ?? 0).toDouble(),
        seconds: j['seconds'] as int? ?? 0,
        topics: ((j['topics'] as Map?) ?? {}).map((k, v) => MapEntry(
            k as String, TopicScore.fromJson(Map<String, dynamic>.from(v as Map)))),
      );
}
