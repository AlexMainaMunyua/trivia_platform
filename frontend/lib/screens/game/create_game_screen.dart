import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/question.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<QuestionForm> _questions = [];

  @override
  void initState() {
    super.initState();
    // Add 5 initial questions
    for (int i = 0; i < 5; i++) {
      _questions.add(QuestionForm());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length < 10) {
      setState(() {
        _questions.add(QuestionForm());
      });
    }
  }

  void _removeQuestion(int index) {
    if (_questions.length > 5) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    }
  }

  Future<void> _createGame() async {
    if (_formKey.currentState!.validate()) {
      final gameData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'questions': _questions.map((q) => q.toJson()).toList(),
      };

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.createGame(gameData);

      if (gameProvider.error == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game created successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(gameProvider.error!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Game'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Game Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return QuestionFormWidget(
                    questionForm: _questions[index],
                    index: index,
                    onRemove: () => _removeQuestion(index),
                    canRemove: _questions.length > 5,
                  );
                },
              ),
              if (_questions.length < 10)
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              const SizedBox(height: 24),
              Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  return ElevatedButton(
                    onPressed: gameProvider.isLoading ? null : _createGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: gameProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Game'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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

class QuestionFormWidget extends StatelessWidget {
  final QuestionForm questionForm;
  final int index;
  final VoidCallback onRemove;
  final bool canRemove;

  const QuestionFormWidget({
    super.key,
    required this.questionForm,
    required this.index,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: questionForm.questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: questionForm.optionAController,
              decoration: const InputDecoration(
                labelText: 'Option A',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter option A';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: questionForm.optionBController,
              decoration: const InputDecoration(
                labelText: 'Option B',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter option B';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: questionForm.optionCController,
              decoration: const InputDecoration(
                labelText: 'Option C',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter option C';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: questionForm.optionDController,
              decoration: const InputDecoration(
                labelText: 'Option D',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter option D';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Correct Answer:'),
            DropdownButtonFormField<String>(
              value: questionForm.correctAnswer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: ['A', 'B', 'C', 'D'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Option $value'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  questionForm.correctAnswer = newValue;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}