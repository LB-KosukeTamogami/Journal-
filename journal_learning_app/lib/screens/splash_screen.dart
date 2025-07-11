import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation_screen.dart';
import 'auth/auth_landing_screen.dart';
import '../services/auth_service.dart';

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
    print('[SplashScreen] Starting navigation logic');
    
    // HTMLスプラッシュ画面の表示を考慮して、即座に遷移
    // HTMLで2秒表示されるので、Flutter側では追加の待機は不要
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) {
      print('[SplashScreen] Widget not mounted, skipping navigation');
      return;
    }
    
    try {
      // 認証状態を確認
      print('[SplashScreen] Checking authentication status');
      final isLoggedIn = AuthService.currentUser != null;
      print('[SplashScreen] User logged in: $isLoggedIn');
      
      // 認証されていない場合は認証ランディング画面へ
      final targetScreen = isLoggedIn ? const MainNavigationScreen() : const AuthLandingScreen();
      
      // フェード効果で遷移
      print('[SplashScreen] Navigating to: ${targetScreen.runtimeType}');
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // フェード効果
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
      print('[SplashScreen] Navigation completed');
    } catch (e, stack) {
      print('[SplashScreen] Navigation error: $e');
      print('[SplashScreen] Stack trace:\n$stack');
      
      // エラーが発生した場合は認証ランディング画面へ
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthLandingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flutter側のスプラッシュ画面は透明にして、HTMLスプラッシュ画面を表示
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(),
    );
  }
}