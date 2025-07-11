import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation_screen.dart';
import 'auth/login_screen.dart';
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
    // HTMLスプラッシュ画面の表示を考慮して、即座に遷移
    // HTMLで2秒表示されるので、Flutter側では追加の待機は不要
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // 認証状態を確認
    final isLoggedIn = AuthService.currentUser != null;
    final targetScreen = isLoggedIn ? const MainNavigationScreen() : const LoginScreen();
    
    // フェード効果で遷移
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