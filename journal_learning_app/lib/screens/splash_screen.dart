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
    
    // アニメーションなしで遷移（HTMLのディゾルブのみ）
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // アニメーションなしで即座に表示
          return child;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 透明なスプラッシュ画面 - HTMLが実際の表示を担当
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}