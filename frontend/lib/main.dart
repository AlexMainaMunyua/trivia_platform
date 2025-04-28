import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/game_provider.dart';
import 'package:frontend/providers/notification_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/auth/register_screen.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/http_client.dart';
import 'package:frontend/splash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService.init();
  await ApiService.init();
  await AuthenticatedHttpClient.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Trivia Platform',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Add the navigator key from http_client.dart
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home:  SplashScreen(), // Start with splash screen instead of AuthWrapper
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

// Keep the AuthWrapper for any usage elsewhere in your app
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}