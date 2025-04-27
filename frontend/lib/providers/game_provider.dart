import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/invitation.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  List<Game> _games = [];
  List<Game> _myGames = [];
  List<GameInvitation> _invitations = [];
  Game? _currentGame;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _lastGameResult;

  List<Game> get games => _games;
  List<Game> get myGames => _myGames;
  List<GameInvitation> get invitations => _invitations;
  Game? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get lastGameResult => _lastGameResult;

  Future<void> fetchGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _games = await ApiService.getGames();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myGames = await ApiService.getMyGames();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGame(Map<String, dynamic> gameData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final game = await ApiService.createGame(gameData);
      _myGames.add(game);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvitations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invitations = await ApiService.getInvitations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendInvitation(int gameId, String receiverIdentifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.sendInvitation(gameId, receiverIdentifier);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respondToInvitation(int invitationId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.respondToInvitation(invitationId, status);
      _invitations.removeWhere((invitation) => invitation.id == invitationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGameForPlay(int gameId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentGame = await ApiService.getGameForPlay(gameId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitGameAnswers(int gameId, List<String> answers) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastGameResult = await ApiService.submitGameAnswers(gameId, answers);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}