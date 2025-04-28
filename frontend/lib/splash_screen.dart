import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/http_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Short delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if token exists
    final token = await StorageService.getToken();
    
    if (token != null) {
      try {
        // Try to get user profile to validate token
        final user = await ApiService.getProfile();
        
        // Valid token, update AuthProvider
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setUser(user);
        
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        // Token invalid or expired
        await StorageService.removeToken();
        AuthenticatedHttpClient.clearToken();
        
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      // No token, navigate to login
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(
                Icons.quiz,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Trivia Platform',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}