import 'package:flutter/material.dart';
import '../views/splash_view/splash_screen.dart';
import 'route_name.dart';

class Routing {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route found for ${settings.name}')),
          ),
        );
    }
  }
}
