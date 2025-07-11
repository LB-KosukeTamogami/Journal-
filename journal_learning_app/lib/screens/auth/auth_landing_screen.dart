import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // ロゴとタイトル
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '🐿️',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ).animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Squirrel',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Journal Language Learning',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(begin: 0.2, end: 0),
                    ],
                  ),
                ],
              ),
              const Spacer(flex: 1),
              // 説明文
              Text(
                '日記を書いて、楽しく言語を学ぼう',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 600.ms),
              const SizedBox(height: 8),
              Text(
                'AIがあなたの日記を添削し、\n自然な表現を学べます',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 700.ms),
              const Spacer(flex: 2),
              // ボタン
              Column(
                children: [
                  // 新規登録ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        '新規登録',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  // ログインボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ログイン',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 900.ms)
                    .slideY(begin: 0.2, end: 0),
                ],
              ),
              const SizedBox(height: 40),
              // フッター
              Text(
                '続行することで、利用規約とプライバシーポリシーに\n同意したものとみなされます',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 1000.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}