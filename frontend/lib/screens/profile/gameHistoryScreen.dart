import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/api_service.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _playedGames = [];
  List<Game> _createdGames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Add API methods to fetch game history
      // For now, we'll just simulate the data
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulated data - replace with actual API calls
      _playedGames = List.generate(10, (index) => {
        'game': Game(
          id: index + 1,
          title: 'Game ${index + 1}',
          description: 'Description for game ${index + 1}',
          questions: [],
          creatorId: 1, isActive: true,
        ),
        'score': (index % 5) + 1,
        'totalQuestions': 5,
        'playedAt': DateTime.now().subtract(Duration(days: index)),
      });
      
      _createdGames = await ApiService.getMyGames();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load game history: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Games Played'),
            Tab(text: 'Games Created'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlayedGamesTab(),
                _buildCreatedGamesTab(),
              ],
            ),
    );
  }

  Widget _buildPlayedGamesTab() {
    if (_playedGames.isEmpty) {
      return const Center(
        child: Text('You haven\'t played any games yet'),
      );
    }

    return ListView.builder(
      itemCount: _playedGames.length,
      itemBuilder: (context, index) {
        final gameData = _playedGames[index];
        final Game game = gameData['game'];
        final int score = gameData['score'];
        final int totalQuestions = gameData['totalQuestions'];
        final DateTime playedAt = gameData['playedAt'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              game.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Score: $score / $totalQuestions'),
             //   Text('Played on: ${DateFormat('MMM d, yyyy').format(playedAt)}'),
              ],
            ),
            trailing: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${(score / totalQuestions * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              // TODO: Navigate to detailed game result screen
            },
          ),
        );
      },
    );
  }

  Widget _buildCreatedGamesTab() {
    if (_createdGames.isEmpty) {
      return const Center(
        child: Text('You haven\'t created any games yet'),
      );
    }

    return ListView.builder(
      itemCount: _createdGames.length,
      itemBuilder: (context, index) {
        final game = _createdGames[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              game.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(game.description),
                const SizedBox(height: 4),
                Text('Questions: ${game.questions.length}'),
             //   Text('Created: ${DateFormat('MMM d, yyyy').format(game.createdAt ?? DateTime.now())}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit game screen
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Game'),
                        content: const Text('Are you sure you want to delete this game? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement delete game
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to view game details
            },
          ),
        );
      },
    );
  }
}