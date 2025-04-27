import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../models/question.dart';
import '../../providers/game_provider.dart';
import 'game_result_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final Game game;

  const GamePlayScreen({super.key, required this.game});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  int _currentQuestionIndex = 0;
  final List<String> _answers = [];
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    await Provider.of<GameProvider>(context, listen: false)
        .loadGameForPlay(widget.game.id);
  }

  void _nextQuestion() {
    if (_selectedAnswer != null) {
      setState(() {
        _answers.add(_selectedAnswer!);
        if (_currentQuestionIndex < widget.game.questions.length - 1) {
          _currentQuestionIndex++;
          _selectedAnswer = null;
        } else {
          _submitGame();
        }
      });
    }
  }

  Future<void> _submitGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.submitGameAnswers(widget.game.id, _answers);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameResultScreen(
            game: widget.game,
            result: gameProvider.lastGameResult!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameProvider.currentGame == null) {
            return const Center(child: Text('Failed to load game'));
          }

          final question = gameProvider.currentGame!.questions[_currentQuestionIndex];
          
          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / gameProvider.currentGame!.questions.length,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${gameProvider.currentGame!.questions.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        question.question,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      _buildOption('A', question.optionA),
                      const SizedBox(height: 12),
                      _buildOption('B', question.optionB),
                      const SizedBox(height: 12),
                      _buildOption('C', question.optionC),
                      const SizedBox(height: 12),
                      _buildOption('D', question.optionD),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _selectedAnswer != null ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentQuestionIndex < gameProvider.currentGame!.questions.length - 1
                              ? 'Next Question'
                              : 'Submit Game',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(String letter, String text) {
    return RadioListTile<String>(
      title: Text('$letter: $text'),
      value: letter,
      groupValue: _selectedAnswer,
      onChanged: (String? value) {
        setState(() {
          _selectedAnswer = value;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _selectedAnswer == letter ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
      ),
    );
  }
}