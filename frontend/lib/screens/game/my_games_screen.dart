import 'package:flutter/material.dart';
import 'package:frontend/screens/game/create_game_screen.dart';
import 'package:frontend/screens/game/game_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';


class MyGamesScreen extends StatefulWidget {
  const MyGamesScreen({super.key});

  @override
  State<MyGamesScreen> createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).fetchMyGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Games'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading && gameProvider.myGames.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameProvider.myGames.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You haven\'t created any games yet.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateGameScreen()),
                      );
                    },
                    child: const Text('Create Game'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: gameProvider.myGames.length,
            itemBuilder: (context, index) {
              final game = gameProvider.myGames[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(game.title),
                  subtitle: Text(game.description),
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
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGameScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}