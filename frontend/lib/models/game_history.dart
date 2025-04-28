class GameHistory {
  final int id;
  final int gameId;
  final String gameTitle;
  final DateTime playedAt;
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  GameHistory({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.playedAt,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['id'],
      gameId: json['game_id'],
      gameTitle: json['game_title'],
      playedAt: DateTime.parse(json['played_at']),
      score: json['score'],
      totalQuestions: json['total_questions'],
      correctAnswers: json['correct_answers'],
    );
  }
}