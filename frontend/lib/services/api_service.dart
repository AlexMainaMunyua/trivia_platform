import 'dart:convert';
import 'package:frontend/models/notificatons.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/game.dart';
import '../models/invitation.dart';
import 'storage_service.dart';

class ApiService {
 // static const String baseUrl = 'http://localhost:8000/api'; // Change this to your API URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static String? _token;

  static Future<void> init() async {
    _token = await StorageService.getToken();
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );



    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      await StorageService.saveToken(_token!);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      await StorageService.saveToken(_token!);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  static Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      _token = null;
      await StorageService.removeToken();
    } else {
      throw Exception('Logout failed');
    }
  }

  // Games
  static Future<List<Game>> getGames() async {
    final response = await http.get(
      Uri.parse('$baseUrl/games'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load games');
    }
  }

  static Future<Game> createGame(Map<String, dynamic> gameData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games'),
      headers: _headers,
      body: jsonEncode(gameData),
    );

    if (response.statusCode == 201) {
      return Game.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create game');
    }
  }

  static Future<List<Game>> getMyGames() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-games'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load games');
    }
  }

  // Invitations
  static Future<void> sendInvitation(int gameId, String receiverIdentifier) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations'),
      headers: _headers,
      body: jsonEncode({
        'game_id': gameId,
        'receiver_identifier': receiverIdentifier,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to send invitation');
    }
  }

  static Future<List<GameInvitation>> getInvitations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/invitations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GameInvitation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invitations');
    }
  }

  static Future<void> respondToInvitation(int invitationId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/invitations/$invitationId/respond'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to respond to invitation');
    }
  }

  // Game Play
  static Future<Game> getGameForPlay(int gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/play/$gameId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Game.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load game');
    }
  }

  static Future<Map<String, dynamic>> submitGameAnswers(int gameId, List<String> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/play/$gameId/submit'),
      headers: _headers,
      body: jsonEncode({'answers': answers}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit answers');
    }
  }

  // Leaderboard
  static Future<List<Map<String, dynamic>>> getGlobalLeaderboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  static Future<List<Map<String, dynamic>>> getGameLeaderboard(int gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard/game/$gameId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load game leaderboard');
    }
  }

  // Notifications
  static Future<List<AppNotification>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }
}

