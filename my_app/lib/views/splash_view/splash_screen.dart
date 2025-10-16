import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/splash_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplashProvider>();

    return Scaffold(
      body: Center(
        child: Text(
          '🚀 Welcome to my_app',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
