import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import 'auth/auth_landing_screen.dart';
import '../services/auth_service.dart';
import '../utils/no_swipe_page_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    // 少し遅延を入れてスプラッシュ画面を表示
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      print('[SplashScreen] Checking authentication status...');
      final isLoggedIn = await AuthService.isLoggedIn();
      print('[SplashScreen] Is logged in: $isLoggedIn');

      if (!mounted) return;

      final targetScreen = isLoggedIn ? MainNavigationScreen(key: MainNavigationScreen.navigatorKey) : const AuthLandingScreen();
      
      // フェード効果で遷移（履歴から削除してスワイプバックを防ぐ）
      print('[SplashScreen] Navigating to: ${targetScreen.runtimeType}');
      await Navigator.of(context).pushAndRemoveUntil(
        NoSwipePageRoute(
          builder: (context) => targetScreen,
          settings: RouteSettings(name: targetScreen.runtimeType.toString()),
        ),
        (route) => false, // すべての履歴を削除
      );
      print('[SplashScreen] Navigation completed');
    } catch (e, stack) {
      print('[SplashScreen] Navigation error: $e');
      print('[SplashScreen] Stack trace:\n$stack');
      
      // エラーが発生した場合は認証ランディング画面へ
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          NoSwipePageRoute(
            builder: (context) => const AuthLandingScreen(),
            settings: const RouteSettings(name: 'AuthLandingScreen'),
          ),
          (route) => false, // すべての履歴を削除
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