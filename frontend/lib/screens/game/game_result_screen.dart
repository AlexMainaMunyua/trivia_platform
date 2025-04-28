import 'package:flutter/material.dart';
import '../../models/game.dart';
import 'dart:math' as math;

class GameResultScreen extends StatefulWidget {
  final Game game;
  final Map<String, dynamic> result;

  const GameResultScreen({
    super.key,
    required this.game,
    required this.result,
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scoreAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Fade animation for content
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );
    
    // Scale animation for trophy icon
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    // Rotate animation for trophy icon
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    // Count-up animation for score
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    // Game result data
    final score = widget.result['score'] as int;
    final total = widget.result['total'] as int;
    final percentage = widget.result['percentage'] as int;
    
    // Determine result quality
    final ResultQuality resultQuality = _getResultQuality(percentage);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              resultQuality.color.withOpacity(0.8),
              resultQuality.color,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: ConfettiPatternPainter(
                    Colors.white.withOpacity(0.15),
                    resultQuality.isSuccess,
                  ),
                  willChange: true,
                ),
              ),
              
              // Main content - Wrapped in SingleChildScrollView to prevent overflow
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 80.0), // Add more bottom padding
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Trophy or badge icon with animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, -20 * (1 - value)),
                                  child: child,
                                );
                              },
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: RotationTransition(
                                  turns: _rotateAnimation,
                                  child: Container(
                                    width: 120, // Reduced size a bit
                                    height: 120, // Reduced size a bit
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      resultQuality.icon,
                                      size: 60, // Reduced size a bit
                                      color: resultQuality.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24), // Reduced spacing
                            
                            // Result title
                            Text(
                              resultQuality.title,
                              style: const TextStyle(
                                fontSize: 28, // Slightly smaller text
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12), // Reduced spacing
                            
                            // Message based on performance
                            Text(
                              resultQuality.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 24), // Reduced spacing
                            
                            // Score container
                            Container(
                              padding: const EdgeInsets.all(20), // Slightly smaller padding
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Your Score',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Animated score
                                  AnimatedBuilder(
                                    animation: _scoreAnimation,
                                    builder: (context, child) {
                                      final displayScore = (score * _scoreAnimation.value).floor();
                                      final displayPercentage = (percentage * _scoreAnimation.value).floor();
                                      
                                      return Column(
                                        children: [
                                          Text(
                                            '$displayScore / $total',
                                            style: const TextStyle(
                                              fontSize: 36, // Slightly smaller text
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Circular progress indicator
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                width: 90, // Slightly smaller
                                                height: 90, // Slightly smaller
                                                child: CircularProgressIndicator(
                                                  value: _scoreAnimation.value * score / total,
                                                  strokeWidth: 8, // Thinner
                                                  backgroundColor: Colors.white.withOpacity(0.3),
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              Text(
                                                '$displayPercentage%',
                                                style: const TextStyle(
                                                  fontSize: 22, // Slightly smaller
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24), // Reduced spacing
                            
                            // Game details
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.game.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32), // Reduced spacing
                            
                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Play again button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Implement play again functionality
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.replay, size: 20),
                                      label: const Text('Play Again'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: resultQuality.color,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12), // Smaller gap
                                  
                                  // Home button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.home, size: 20),
                                      label: const Text('Home'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Close button in the corner
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  ResultQuality _getResultQuality(int percentage) {
    if (percentage >= 90) {
      return ResultQuality(
        title: 'Excellent!',
        message: 'Amazing work! Your knowledge is truly impressive.',
        icon: Icons.emoji_events,
        color: Colors.amber[700]!,
        isSuccess: true,
      );
    } else if (percentage >= 70) {
      return ResultQuality(
        title: 'Great Job!',
        message: 'Well done! You have a solid understanding of this topic.',
        icon: Icons.star,
        color: Colors.green[700]!,
        isSuccess: true,
      );
    } else if (percentage >= 50) {
      return ResultQuality(
        title: 'Good Effort!',
        message: 'Nice try! Keep practicing to improve your score.',
        icon: Icons.thumb_up,
        color: Colors.blue[700]!,
        isSuccess: true,
      );
    } else {
      return ResultQuality(
        title: 'Keep Trying!',
        message: 'Don\'t give up! Practice makes perfect.',
        icon: Icons.school,
        color: Colors.purple[700]!,
        isSuccess: false,
      );
    }
  }
}

class ResultQuality {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool isSuccess;
  
  ResultQuality({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.isSuccess,
  });
}

class ConfettiPatternPainter extends CustomPainter {
  final Color color;
  final bool showConfetti;
  final Random random = Random(DateTime.now().millisecondsSinceEpoch);
  
  ConfettiPatternPainter(this.color, this.showConfetti);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // For success results, draw confetti
    if (showConfetti) {
      for (int i = 0; i < 100; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final width = 2.0 + random.nextDouble() * 8;
        final height = 2.0 + random.nextDouble() * 8;
        
        // Randomly choose between circle, rectangle, or triangle confetti
        final shape = random.nextInt(3);
        
        switch (shape) {
          case 0: // Circle
            canvas.drawCircle(Offset(x, y), width / 2, paint);
            break;
          case 1: // Rectangle
            canvas.drawRect(
              Rect.fromLTWH(x, y, width, height),
              paint,
            );
            break;
          case 2: // Triangle
            final path = Path();
            path.moveTo(x, y);
            path.lineTo(x + width, y + height);
            path.lineTo(x - width, y + height);
            path.close();
            canvas.drawPath(path, paint);
            break;
        }
      }
    } else {
      // For non-success results, draw subtle pattern
      for (int i = 0; i < 50; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final radius = 2.0 + random.nextDouble() * 6;
        
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Random {
  final math.Random _random;
  
  Random(int seed) : _random = math.Random(seed);
  
  double nextDouble() => _random.nextDouble();
  
  int nextInt(int max) => _random.nextInt(max);
}