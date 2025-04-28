import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/http_client.dart'; // Import HTTP client

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        // Update the HTTP client token
        AuthenticatedHttpClient.updateToken(token);
        
        final userData = await StorageService.getUserData();
        if (userData != null) {
          _user = User.fromJson(userData);
          notifyListeners();
          
          // Optional: Validate token by making an API call
          // This ensures the token is still valid on the server
          // But we'll do this silently, without setting loading state
          try {
            await ApiService.getProfile();
          } catch (e) {
            // If validation fails, clear user data
            if (e.toString().contains('401')) {
              _user = null;
              await StorageService.clearAll();
              AuthenticatedHttpClient.clearToken();
              notifyListeners();
            }
          }
        }
      } catch (e) {
        // Handle any other errors during initialization
        print('Error during auth check: $e');
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      _user = User.fromJson(response['user']);
      await StorageService.saveUserData(response['user']);
      
      // Make sure HTTP client has the token
      AuthenticatedHttpClient.updateToken(response['token']);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, String> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      _user = User.fromJson(response['user']);
      await StorageService.saveUserData(response['user']);
      
      // Make sure HTTP client has the token
      AuthenticatedHttpClient.updateToken(response['token']);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      // Even if logout API fails, we still want to clear local data
      _error = e.toString();
    } finally {
      // Clear all local data regardless of API success
      _user = null;
      await StorageService.clearAll();
      AuthenticatedHttpClient.clearToken();
      
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add the setUser method for external updates
  void setUser(User user) {
    _user = user;
    StorageService.saveUserData(user.toJson());
    notifyListeners();
  }
  
  // Force logout without API call - used for session expiration
  void forceLogout() {
    _user = null;
    StorageService.clearAll();
    AuthenticatedHttpClient.clearToken();
    notifyListeners();
  }
  
  // Refresh user data from API
  Future<void> refreshUserData(BuildContext context) async {
    try {
      final freshUser = await ApiService.getProfile();
      _user = freshUser;
      await StorageService.saveUserData(freshUser.toJson());
      notifyListeners();
    } catch (e) {
      // Use our global error handler
      ApiService.handleApiError(e, context);
    }
  }
}