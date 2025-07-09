import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    
    // 回転アニメーション
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // パルスアニメーション
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // パーティクルアニメーション
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _navigateToHome();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
        transitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          var fadeAnimation = animation.drive(tween);
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // アニメーション背景
          ...List.generate(3, (index) => _buildFloatingCircle(index)),
          
          // パーティクルエフェクト
          ..._buildParticles(),
          
          // メインコンテンツ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // リスのアイコンコンテナ
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外側の光るリング
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120 + (_pulseController.value * 20),
                          height: 120 + (_pulseController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3 - (_pulseController.value * 0.2)),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // メインアイコンコンテナ
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🐿️',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 1000.ms)
                        .scale(
                          duration: 1200.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                        )
                        .then()
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          duration: 2000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                        ),
                  ],
                ),
                const SizedBox(height: 32),
                // アプリ名
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Squirrel',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          blurRadius: 30,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 1000.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 500.ms,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .blur(
                      begin: const Offset(10, 10),
                      end: const Offset(0, 0),
                      delay: 500.ms,
                      duration: 800.ms,
                    ),
                const SizedBox(height: 8),
                // サブタイトル
                Text(
                  'Journal Language Learning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 1000.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 800.ms,
                      duration: 600.ms,
                    ),
              ],
            ),
          ),
          // プログレスインジケーター
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 150,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 3000),
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 800.ms),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingCircle(int index) {
    final positions = [
      const {'top': -100.0, 'right': -100.0},
      const {'bottom': -150.0, 'left': -150.0},
      const {'top': 200.0, 'left': -80.0},
    ];
    
    final sizes = [250.0, 350.0, 180.0];
    final delays = [0, 200, 400];
    
    return Positioned(
      top: positions[index]['top'],
      bottom: positions[index]['bottom'],
      left: positions[index]['left'],
      right: positions[index]['right'],
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi * (index.isEven ? 1 : -1),
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          );
        },
      )
          .animate()
          .fadeIn(duration: 1500.ms, delay: delays[index].ms)
          .scale(
            duration: 1500.ms,
            delay: delays[index].ms,
            curve: Curves.easeOut,
          ),
    );
  }
  
  List<Widget> _buildParticles() {
    return List.generate(20, (index) {
      final random = math.Random(index);
      final startX = random.nextDouble() * 400 - 200;
      final startY = random.nextDouble() * 800 - 400;
      final size = random.nextDouble() * 4 + 2;
      final duration = random.nextInt(3000) + 2000;
      final delay = random.nextInt(1000);
      
      return Positioned(
        left: startX,
        top: startY,
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_particleController.value * 2 * math.pi) * 30,
                -_particleController.value * 100,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: size * 2,
                      spreadRadius: size / 2,
                    ),
                  ],
                ),
              ),
            );
          },
        )
            .animate()
            .fadeIn(delay: delay.ms, duration: 500.ms)
            .then()
            .animate(onPlay: (controller) => controller.repeat())
            .fadeOut(duration: duration.ms)
            .then(delay: 500.ms)
            .fadeIn(duration: 500.ms),
      );
    });
  }
}