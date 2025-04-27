import 'package:frontend/models/question.dart';
import 'package:frontend/models/user.dart';

class Game {
  final int id;
  final String title;
  final String description;
  final int creatorId;
  final bool isActive;
  final List<Question> questions;
  final User? creator;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.isActive,
    this.questions = const [],
    this.creator,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creator_id'],
      isActive: json['is_active'],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
    );
  }
}