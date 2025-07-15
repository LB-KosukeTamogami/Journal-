import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class TestSplashScreen extends StatefulWidget {
  const TestSplashScreen({super.key});

  @override
  State<TestSplashScreen> createState() => _TestSplashScreenState();
}

class _TestSplashScreenState extends State<TestSplashScreen> {
  @override
  void initState() {
    super.initState();
    print('[TestSplashScreen] initState - Starting timer');
    Future.delayed(const Duration(seconds: 2), () {
      print('[TestSplashScreen] Timer finished, checking mounted state');
      if (mounted) {
        print('[TestSplashScreen] Widget is mounted, navigating...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              print('[TestSplashScreen] Building MainNavigationScreen');
              return const MainNavigationScreen();
            },
          ),
        );
      } else {
        print('[TestSplashScreen] Widget not mounted, skipping navigation');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('[TestSplashScreen] Building widget');
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: const Center(
        child: Text(
          'Squirrel',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}