import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import 'auth/auth_landing_screen.dart';
import '../services/auth_service.dart';
<<<<<<< HEAD
=======
import '../utils/no_swipe_page_route.dart';
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe

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
    
    // Supabaseの初期化とセッション復元を待つ（スマホブラウザで重要）
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) {
      print('[SplashScreen] Widget not mounted, skipping navigation');
      return;
    }
    
    try {
      // 認証状態を確認（セッション復元を待つ）
      print('[SplashScreen] Checking authentication status');
      
      // スマホブラウザでのセッション復元を確実にするため、再度チェック
      final user = AuthService.currentUser;
      if (user == null) {
        // 少し待ってから再度確認（スマホブラウザでの遅延対策）
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final isLoggedIn = AuthService.currentUser != null;
      print('[SplashScreen] User logged in: $isLoggedIn');
      print('[SplashScreen] User ID: ${AuthService.currentUser?.id}');
      
      // 認証されていない場合は認証ランディング画面へ
<<<<<<< HEAD
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
=======
      final targetScreen = isLoggedIn ? MainNavigationScreen(key: MainNavigationScreen.navigatorKey) : const AuthLandingScreen();
      
      // フェード効果で遷移（履歴から削除してスワイプバックを防ぐ）
      print('[SplashScreen] Navigating to: ${targetScreen.runtimeType}');
      await Navigator.of(context).pushAndRemoveUntil(
        NoSwipePageRoute(
          builder: (context) => targetScreen,
          settings: RouteSettings(name: targetScreen.runtimeType.toString()),
        ),
        (route) => false, // すべての履歴を削除
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
      );
      print('[SplashScreen] Navigation completed');
    } catch (e, stack) {
      print('[SplashScreen] Navigation error: $e');
      print('[SplashScreen] Stack trace:\n$stack');
      
      // エラーが発生した場合は認証ランディング画面へ
      if (mounted) {
<<<<<<< HEAD
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthLandingScreen()),
=======
        Navigator.of(context).pushAndRemoveUntil(
          NoSwipePageRoute(
            builder: (context) => const AuthLandingScreen(),
            settings: const RouteSettings(name: 'AuthLandingScreen'),
          ),
          (route) => false, // すべての履歴を削除
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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