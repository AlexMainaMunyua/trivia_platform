// Create this file as a new class that will handle HTTP requests with authentication
// lib/services/http_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

// Global key to access navigator state from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthenticatedHttpClient {
  static String? _token;
  static final String baseUrl = 'https://phplaravel-1453572-5459994.cloudwaysapps.com/api';
  
  // Initialize with token
  static Future<void> init() async {
    _token = await StorageService.getToken();
  }
  
  // Headers with authentication
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  
  // GET request
  static Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  // POST request
  static Future<http.Response> post(String endpoint, {dynamic body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    return _handleResponse(response);
  }
  
  // PUT request
  static Future<http.Response> put(String endpoint, {dynamic body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    return _handleResponse(response);
  }
  
  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  // Handle unauthorized response
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception('Your session has expired. Please log in again.');
    }
    
    return response;
  }
  
  // Handle 401 unauthorized errors
  static Future<void> _handleUnauthorized() async {
    // Clear token
    _token = null;
    await StorageService.removeToken();
    
    // Navigate to login screen
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Show a snackbar message
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate to login
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  
  // Update token
  static void updateToken(String token) {
    _token = token;
  }
  
  // Clear token
  static void clearToken() {
    _token = null;
  }
}