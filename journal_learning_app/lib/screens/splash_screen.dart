import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // フォント読み込みを並行して行い、画面表示をブロックしない
    GoogleFonts.pendingFonts([
      GoogleFonts.roboto(fontWeight: FontWeight.w800),
    ]);
    
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // ディゾルブ効果：両方の画面を同時にフェード
          return Stack(
            children: [
              // ホーム画面をフェードイン
              FadeTransition(
                opacity: animation,
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: Center(
          child: RepaintBoundary(
            child: Text(
              'Squirrel',
              style: GoogleFonts.roboto(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
                fontStyle: FontStyle.normal,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
      theme: ThemeData(
        // 完全に独立したテーマを使用してフォントの影響を排除
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}