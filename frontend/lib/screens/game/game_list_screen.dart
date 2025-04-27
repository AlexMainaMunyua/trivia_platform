import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/game.dart';
import 'game_detail_screen.dart';
import 'create_game_screen.dart';

class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGameScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading && gameProvider.games.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${gameProvider.error}'),
                  ElevatedButton(
                    onPressed: () => gameProvider.fetchGames(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (gameProvider.games.isEmpty) {
            return const Center(
              child: Text('No games available. Create one!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => gameProvider.fetchGames(),
            child: ListView.builder(
              itemCount: gameProvider.games.length,
              itemBuilder: (context, index) {
                final game = gameProvider.games[index];
                return GameCard(game: game);
              },
            ),
          );
        },
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(game.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game.description),
            const SizedBox(height: 4),
            Text(
              'Created by: ${game.creator?.name ?? 'Unknown'}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(game: game),
            ),
          );
        },
      ),
    );
  }
}
