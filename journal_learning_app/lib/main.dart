import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';

void main() async {
  // エラーハンドリングを設定
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error caught:');
    print('Error: ${details.exception}');
    if (details.stack != null) {
      print('Stack trace:\n${details.stack}');
    }
  };
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('[Main] Starting app initialization');
    
    // StorageServiceの初期化
    try {
      print('[Main] Initializing StorageService...');
      await StorageService.init();
      print('[Main] StorageService initialized successfully');
      
      print('[Main] Initializing sample data...');
      await StorageService.initializeSampleData();
      print('[Main] Sample data initialized successfully');
    } catch (e, stack) {
      print('[Main] Storage initialization error: $e');
      print('[Main] Stack trace:\n$stack');
    }
    
    // Supabaseの設定情報を出力
    SupabaseConfig.printDebugInfo();
    
    // SupabaseServiceの初期化
    try {
      print('[Main] Initializing SupabaseService...');
      await SupabaseService.initialize();
      print('[Main] SupabaseService initialization completed');
    } catch (e, stack) {
      print('[Main] Supabase initialization error: $e');
      print('[Main] Stack trace:\n$stack');
      // Supabaseの初期化に失敗しても、アプリは起動する
    }
    
    print('[Main] Running MyApp...');
    runApp(const MyApp());
  } catch (e, stack) {
    print('[Main] Fatal error during app initialization: $e');
    print('[Main] Stack trace:\n$stack');
    // エラー画面を表示
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('App initialization failed: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squirrel - Journal Language Learning',
      theme: AppTheme.lightTheme.copyWith(
        // 包括的なフォントフォールバックを追加
        textTheme: AppTheme.lightTheme.textTheme.apply(
          fontFamilyFallback: [
            'Noto Sans JP', 
            'Noto Sans', 
            'Noto Emoji',
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
            'Segoe UI Symbol',
            'Noto Sans CJK JP',
            'Noto Sans CJK',
            'Hiragino Sans',
            'Yu Gothic',
            'Meiryo',
            'Takao',
            'IPAexGothic',
            'IPAPGothic',
            'sans-serif'
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}