import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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

class _GamePlayScreenState extends State<GamePlayScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final List<String> _answers = [];
  String? _selectedAnswer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Timer variables
  Timer? _timer;
  int _timeRemaining = 30; // 30 seconds per question
  bool _isTimeAlmostUp = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Fade animation for question and options
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Slide animation for question and options
    _slideAnimation = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start the timer
    _startTimer();
    
    // Start animation
    _animationController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = 30;
      _isTimeAlmostUp = false;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
          // Set flag when time is running low (less than 10 seconds)
          _isTimeAlmostUp = _timeRemaining < 10;
        } else {
          // Time's up - move to next question or submit
          _timer?.cancel();
          if (_selectedAnswer == null) {
            // If no answer selected, choose empty string
            _answers.add('');
            if (_currentQuestionIndex < widget.game.questions.length - 1) {
              _goToNextQuestion();
            } else {
              _submitGame();
            }
          }
        }
      });
    });
  }

  Future<void> _loadGame() async {
    await Provider.of<GameProvider>(context, listen: false)
        .loadGameForPlay(widget.game.id);
  }

  void _goToNextQuestion() {
    // Reset animation controller
    _animationController.reset();
    
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
    });
    
    // Start animation for new question
    _animationController.forward();
    
    // Restart timer for new question
    _startTimer();
  }

  void _nextQuestion() {
    if (_selectedAnswer != null) {
      setState(() {
        _answers.add(_selectedAnswer!);
        if (_currentQuestionIndex < widget.game.questions.length - 1) {
          _goToNextQuestion();
        } else {
          _submitGame();
        }
      });
    }
  }

  Future<void> _submitGame() async {
    // Cancel timer
    _timer?.cancel();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.submitGameAnswers(widget.game.id, _answers);
    
    if (mounted) {
      // Dismiss loading dialog
      Navigator.pop(context);
      
      // Navigate to results
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
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          // Timer display in app bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _isTimeAlmostUp 
                ? Colors.red.withOpacity(0.2) 
                : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: _isTimeAlmostUp 
                    ? Colors.red 
                    : theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isTimeAlmostUp 
                      ? Colors.red 
                      : theme.colorScheme.primary,
                    fontSize: _isTimeAlmostUp ? 16 : 14,
                  ),
                  child: Text('$_timeRemaining'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your quiz...'),
                ],
              ),
            );
          }

          if (gameProvider.currentGame == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load game'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final question = gameProvider.currentGame!.questions[_currentQuestionIndex];
          final totalQuestions = gameProvider.currentGame!.questions.length;
          
          return Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${((_currentQuestionIndex + 1) / totalQuestions * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / totalQuestions,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Question and Options
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Question text
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  question.question,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Answer options
                              _buildOption('A', question.optionA, theme),
                              const SizedBox(height: 12),
                              _buildOption('B', question.optionB, theme),
                              const SizedBox(height: 12),
                              _buildOption('C', question.optionC, theme),
                              const SizedBox(height: 12),
                              _buildOption('D', question.optionD, theme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Next button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer != null ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentQuestionIndex < gameProvider.currentGame!.questions.length - 1
                              ? 'NEXT QUESTION'
                              : 'FINISH QUIZ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentQuestionIndex < gameProvider.currentGame!.questions.length - 1
                              ? Icons.arrow_forward
                              : Icons.check_circle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOption(String letter, String text, ThemeData theme) {
    final isSelected = _selectedAnswer == letter;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : Colors.white,
        boxShadow: isSelected ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAnswer = letter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}