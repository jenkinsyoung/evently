import 'package:evently/app/features/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:evently/app/app.dart';
import 'package:evently/app/features/splash/splash_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const App());
      case '/auth':
        return MaterialPageRoute(builder: (_) => const AuthPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const App());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}