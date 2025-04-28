import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/question.dart';
import 'dart:math' as math;

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<QuestionForm> _questions = [];

  late AnimationController _animationController;

  String _selectedCategory = 'General Knowledge';
  final List<String> _categories = [
    'General Knowledge',
    'Science',
    'History',
    'Geography',
    'Movies',
    'Music',
    'Sports',
    'Literature',
    'Technology',
    'Art'
  ];

  String _difficulty = 'Medium';
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];

  int _timeLimit = 20;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    for (int i = 0; i < 5; i++) {
      _questions.add(QuestionForm());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    for (var question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length < 10) {
      setState(() {
        _questions.add(QuestionForm());
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _removeQuestion(int index) {
    if (_questions.length > 5) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A game must have at least 5 questions'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createGame() async {
    if (_formKey.currentState!.validate()) {
      final gameData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'difficulty': _difficulty,
        'time_limit': _timeLimit,
        'questions': _questions.map((q) => q.toJson()).toList(),
      };

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.createGame(gameData);

      if (gameProvider.error == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game created successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors highlighted in red'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'General Knowledge': Colors.blue,
      'Science': Colors.green,
      'History': Colors.amber,
      'Geography': Colors.purple,
      'Movies': Colors.red,
      'Music': Colors.pink,
      'Sports': Colors.orange,
      'Literature': Colors.teal,
      'Technology': Colors.indigo,
      'Art': Colors.deepOrange,
    };
    return colors[category] ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create a New Game', style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return TextButton.icon(
                onPressed: gameProvider.isLoading ? null : _createGame,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.white60,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                //  _buildGameDetailsCard(),
                  _buildQuestionsSection(),
                  _buildAddQuestionButton(),
                  _buildCreateGameButton(gameProvider),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Questions', Icons.quiz),
              Text(
                '${_questions.length}/10',
                style: TextStyle(
                  fontSize: 14,
                  color: _questions.length == 10 ? Colors.red : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            final isNewQuestion = index == _questions.length - 1 &&
                _animationController.status == AnimationStatus.forward;

            Widget questionWidget = QuestionFormWidget(
              questionForm: _questions[index],
              index: index,
              onRemove: () => _removeQuestion(index),
              canRemove: _questions.length > 5,
              categoryColor: _getCategoryColor(_selectedCategory).withOpacity(0.7),
            );

            if (isNewQuestion) {
              return FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: questionWidget,
                ),
              );
            }

            return questionWidget;
          },
        ),
      ],
    );
  }

  Widget _buildAddQuestionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _questions.length < 10
          ? ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            )
          : Text(
              'Maximum number of questions reached (10)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  Widget _buildCreateGameButton(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: gameProvider.isLoading ? null : _createGame,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          'Create Game',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[800]),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownFormField({
    required dynamic value,
    required String label,
    required List<String> items,
    required IconData prefixIcon,
    Color? iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(prefixIcon, color: iconColor),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class QuestionForm {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  String correctAnswer = 'A';

  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'question': questionController.text,
      'option_a': optionAController.text,
      'option_b': optionBController.text,
      'option_c': optionCController.text,
      'option_d': optionDController.text,
      'correct_answer': correctAnswer,
    };
  }
}

class QuestionFormWidget extends StatefulWidget {
  final QuestionForm questionForm;
  final int index;
  final VoidCallback onRemove;
  final bool canRemove;
  final Color categoryColor;

  const QuestionFormWidget({
    super.key,
    required this.questionForm,
    required this.index,
    required this.onRemove,
    required this.canRemove,
    required this.categoryColor,
  });

  @override
  State<QuestionFormWidget> createState() => _QuestionFormWidgetState();
}

class _QuestionFormWidgetState extends State<QuestionFormWidget> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.index == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildQuestionHeader(),
          if (!_expanded) _buildQuestionPreview(),
          if (_expanded) _buildExpandedQuestionForm(),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.categoryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${widget.index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white70),
                    onPressed: widget.onRemove,
                    tooltip: 'Remove question',
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 36,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  tooltip: _expanded ? 'Collapse' : 'Expand',
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 36,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.questionForm.questionController.text.isEmpty
                  ? 'Click to add question details'
                  : widget.questionForm.questionController.text,
              style: TextStyle(
                color: widget.questionForm.questionController.text.isEmpty
                    ? Colors.grey
                    : Colors.black87,
                fontStyle: widget.questionForm.questionController.text.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.categoryColor,
                width: 1,
              ),
            ),
            child: Text(
              'Answer: ${widget.questionForm.correctAnswer}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.categoryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedQuestionForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.questionForm.questionController,
            decoration: InputDecoration(
              labelText: 'Question',
              hintText: 'Enter your question here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a question';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildOptionField(
            controller: widget.questionForm.optionAController,
            label: 'Option A',
            isCorrect: widget.questionForm.correctAnswer == 'A',
            onSetCorrect: () {
              setState(() {
                widget.questionForm.correctAnswer = 'A';
              });
            },
          ),
          const SizedBox(height: 12),
          _buildOptionField(
            controller: widget.questionForm.optionBController,
            label: 'Option B',
            isCorrect: widget.questionForm.correctAnswer == 'B',
            onSetCorrect: () {
              setState(() {
                widget.questionForm.correctAnswer = 'B';
              });
            },
          ),
          const SizedBox(height: 12),
          _buildOptionField(
            controller: widget.questionForm.optionCController,
            label: 'Option C',
            isCorrect: widget.questionForm.correctAnswer == 'C',
            onSetCorrect: () {
              setState(() {
                widget.questionForm.correctAnswer = 'C';
              });
            },
          ),
          const SizedBox(height: 12),
          _buildOptionField(
            controller: widget.questionForm.optionDController,
            label: 'Option D',
            isCorrect: widget.questionForm.correctAnswer == 'D',
            onSetCorrect: () {
              setState(() {
                widget.questionForm.correctAnswer = 'D';
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Correct Answer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.questionForm.correctAnswer,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                  items: ['A', 'B', 'C', 'D'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Option $value'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        widget.questionForm.correctAnswer = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionField({
    required TextEditingController controller,
    required String label,
    required bool isCorrect,
    required VoidCallback onSetCorrect,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isCorrect ? widget.categoryColor.withOpacity(0.1) : Colors.white,
              labelStyle: TextStyle(
                color: isCorrect ? widget.categoryColor : null,
                fontWeight: isCorrect ? FontWeight.bold : null,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ),
        IconButton(
          icon: Icon(
            isCorrect ? Icons.check_circle : Icons.circle_outlined,
            color: isCorrect ? widget.categoryColor : Colors.grey,
          ),
          onPressed: onSetCorrect,
          tooltip: 'Set as correct answer',
        ),
      ],
    );
  }
}
