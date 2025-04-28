class LeaderboardEntry {
  final int userId;
  final String username;
  final String name;
  final int score;
  final int rank;
  final int gamesPlayed;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.name,
    required this.score,
    required this.rank,
    required this.gamesPlayed,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'],
      name: json['name'],
      score: json['score'],
      rank: json['rank'],
      gamesPlayed: json['games_played'],
    );
  }
}