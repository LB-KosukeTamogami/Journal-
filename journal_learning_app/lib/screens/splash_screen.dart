import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
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
    print('[SplashScreen] initState called');
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    print('[SplashScreen] Starting navigation timer...');
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) {
      print('[SplashScreen] Widget not mounted, canceling navigation');
      return;
    }
    
    print('[SplashScreen] Navigating to MainNavigationScreen...');
    try {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
      print('[SplashScreen] Navigation completed');
    } catch (e) {
      print('[SplashScreen] Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // 背景の装飾的な円
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            )
                .animate()
                .fadeIn(duration: 1000.ms)
                .scale(delay: 200.ms, duration: 800.ms),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            )
                .animate()
                .fadeIn(duration: 1000.ms)
                .scale(delay: 400.ms, duration: 800.ms),
          ),
          // メインコンテンツ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // リスのアイコン
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Center(
                    child: Text(
                      '🐿️',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 8),
                // アプリ名
                Text(
                  'Squirrel',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 800.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 300.ms,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
          // ローディングインジケーター
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  minHeight: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 500.ms)
                  .then()
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}