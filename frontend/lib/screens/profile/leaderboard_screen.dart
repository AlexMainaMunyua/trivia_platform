import 'package:flutter/material.dart';
import 'package:frontend/models/userScore.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = false;
  List<UserScore> _leaderboard = [];
  Game? _selectedGame;
  List<Game> _myGames = [];

  @override
  void initState() {
    super.initState();
    _fetchGlobalLeaderboard();
    _fetchMyGames();
  }

  Future<void> _fetchGlobalLeaderboard() async {
    setState(() {
      _isLoading = true;
      _selectedGame = null;
    });

    try {
      // Pass the context to handle 401 errors
      _leaderboard = await ApiService.getGlobalLeaderboard();
      
      // Assign ranks if they're not provided by the API
      if (_leaderboard.isNotEmpty && _leaderboard[0].rank == 0) {
        _assignRanks();
      }
    } catch (e) {
      // Avoid showing error if widget is disposed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leaderboard: ${e.toString()}')),
        );
      }
    } finally {
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Assign ranks based on score
  void _assignRanks() {
    // Sort by score descending
    _leaderboard.sort((a, b) => b.score.compareTo(a.score));
    
    // Create a temporary list with ranks
    final rankedList = <UserScore>[];
    
    int currentRank = 1;
    int previousScore = -1;
    
    for (int i = 0; i < _leaderboard.length; i++) {
      final score = _leaderboard[i];
      
      // If the score is different from the previous one, increment the rank
      if (previousScore != score.score && i > 0) {
        currentRank = i + 1;
      }
      
      // Create a new UserScore with the assigned rank
      rankedList.add(UserScore(
        userId: score.userId,
        score: score.score,
        rank: currentRank,
        name: score.name,
        username: score.username,
        avatar: score.avatar,
        gamesPlayed: score.gamesPlayed,
      ));
      
      previousScore = score.score;
    }
    
    _leaderboard = rankedList;
  }

  Future<void> _fetchGameLeaderboard(int gameId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pass the context to handle 401 errors
      _leaderboard = await ApiService.getGameLeaderboard(gameId);
      
      // Assign ranks if they're not provided by the API
      if (_leaderboard.isNotEmpty && _leaderboard[0].rank == 0) {
        _assignRanks();
      }
      
      _selectedGame = _myGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => Game(
          id: gameId,
          title: 'Game #$gameId',
          description: '',
          questions: [],
          creatorId: 0,
         isActive: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load game leaderboard: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMyGames() async {
    try {
      _myGames = await ApiService.getMyGames();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load games: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGame != null 
            ? '${_selectedGame!.title} Leaderboard' 
            : 'Global Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showGameFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedGame != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Show Global Leaderboard'),
                      onPressed: _fetchGlobalLeaderboard,
                    ),
                  ),
                Expanded(
                  child: _leaderboard.isEmpty
                      ? const Center(child: Text('No leaderboard data available'))
                      : ListView.builder(
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final score = _leaderboard[index];
                            final bool isCurrentUser = currentUser != null && 
                                score.userId == currentUser.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4, 
                                horizontal: 16,
                              ),
                              color: isCurrentUser 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: ListTile(
                                leading: _buildRankBadge(score.rank),
                                title: Text(
                                  score.name,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('@${score.username}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Score: ${score.score}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        Text('Games: ${score.gamesPlayed}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? badgeIcon;
    
    // Determine badge color and icon based on rank
    if (rank == 1) {
      badgeColor = Colors.amber; // Gold
      badgeIcon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey[300]!; // Silver
      badgeIcon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!; // Bronze
      badgeIcon = Icons.emoji_events;
    } else {
      badgeColor = Theme.of(context).colorScheme.surface;
      badgeIcon = null;
    }
    
    return CircleAvatar(
      backgroundColor: badgeColor,
      child: badgeIcon != null 
          ? Icon(badgeIcon, color: Colors.white)
          : Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  void _showGameFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Game',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Global Leaderboard'),
                selected: _selectedGame == null,
                onTap: () {
                  Navigator.pop(context);
                  _fetchGlobalLeaderboard();
                },
              ),
              Expanded(
                child: _myGames.isEmpty
                    ? const Center(child: Text('No games found'))
                    : ListView.builder(
                        itemCount: _myGames.length,
                        itemBuilder: (context, index) {
                          final game = _myGames[index];
                          return ListTile(
                            leading: const Icon(Icons.games),
                            title: Text(game.title),
                            selected: _selectedGame?.id == game.id,
                            onTap: () {
                              Navigator.pop(context);
                              _fetchGameLeaderboard(game.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}