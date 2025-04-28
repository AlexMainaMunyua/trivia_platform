// models/userScore.dart

class UserScore {
  final int userId;
  final int score;
  final int rank;
  final String name;
  final String username;
  final String? avatar;
  final int gamesPlayed;

  UserScore({
    required this.userId,
    required this.score,
    required this.rank,
    required this.name,
    required this.username,
    this.avatar,
    required this.gamesPlayed,
  });

  factory UserScore.fromJson(Map<String, dynamic> json) {
    // Get user info from the nested user object
    final userJson = json['user'] as Map<String, dynamic>?;
    
    return UserScore(
      userId: json['user_id'] as int,
      // Handle score that might come as a string or int
      score: json['total_score'] is String 
          ? int.parse(json['total_score']) 
          : (json['total_score'] as int? ?? 0),
      // Rank might not be in the response, so default to position in list + 1
      rank: json['rank'] as int? ?? 0,
      // Get name and username from the nested user object
      name: userJson?['name'] as String? ?? 'Unknown',
      username: userJson?['username'] as String? ?? 'unknown',
      // Avatar might not exist
      avatar: userJson?['avatar'] as String?,
      // Games played
      gamesPlayed: json['games_played'] as int? ?? 0,
    );
  }
}