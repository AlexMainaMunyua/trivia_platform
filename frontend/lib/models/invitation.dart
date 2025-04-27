import 'package:frontend/models/game.dart';
import 'package:frontend/models/user.dart';

class GameInvitation {
  final int id;
  final int gameId;
  final int senderId;
  final int receiverId;
  final String status;
  final Game? game;
  final User? sender;

  GameInvitation({
    required this.id,
    required this.gameId,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.game,
    this.sender,
  });

  factory GameInvitation.fromJson(Map<String, dynamic> json) {
    return GameInvitation(
      id: json['id'],
      gameId: json['game_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      game: json['game'] != null ? Game.fromJson(json['game']) : null,
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    );
  }
}