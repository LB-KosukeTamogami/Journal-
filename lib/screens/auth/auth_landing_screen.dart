import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
<<<<<<< HEAD
=======
import '../../utils/no_swipe_page_route.dart';
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
import 'login_screen.dart';
import 'signup_screen.dart';
import '../debug/env_check_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
=======
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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
                      ),
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
                      ),
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
              ),
              const SizedBox(height: 8),
              Text(
                'AIがあなたの日記を添削し、\n自然な表現を学べます',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // ボタン
              Column(
                children: [
                  // 新規登録ボタン
                  AppButtonStyles.withShadow(
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
<<<<<<< HEAD
                          MaterialPageRoute(
=======
                          NoSwipePageRoute(
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
<<<<<<< HEAD
                      style: AppButtonStyles.primaryButton.copyWith(
=======
                      style: AppButtonStyles.primaryButton(context).copyWith(
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                        textStyle: MaterialStateProperty.all(
                          AppTheme.button.copyWith(fontSize: 18),
                        ),
                      ),
                      child: const Text('新規登録'),
                    ),
<<<<<<< HEAD
=======
                    Theme.of(context).primaryColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                  ),
                  const SizedBox(height: 16),
                  // ログインボタン
                  AppButtonStyles.withShadow(
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
<<<<<<< HEAD
                          MaterialPageRoute(
=======
                          NoSwipePageRoute(
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
<<<<<<< HEAD
                      style: AppButtonStyles.secondaryButton.copyWith(
=======
                      style: AppButtonStyles.secondaryButton(context).copyWith(
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                        textStyle: MaterialStateProperty.all(
                          AppTheme.button.copyWith(
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      child: const Text('ログイン'),
                    ),
<<<<<<< HEAD
=======
                    Theme.of(context).primaryColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                  ),
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
              ),
              const SizedBox(height: 24),
              // Debug button (always show for now to debug Vercel)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnvCheckScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '🔧 環境設定を確認',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}