import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // HTMLスプラッシュ画面が2秒表示されるので、少し待ってからナビゲート
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;
    
    // フェード効果で遷移
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // フェード効果
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Flutter側でも同じスプラッシュ画面を表示
    return Scaffold(
      backgroundColor: const Color(0xFF8B6D47),
      body: Center(
        child: Text(
          'Squirrel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}