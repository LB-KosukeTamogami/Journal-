import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';
import 'providers/theme_provider.dart';

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
      
      // 日本語の単語を削除（一度だけ実行）
      print('[Main] Cleaning up Japanese words...');
      await StorageService.deleteJapaneseWords();
      print('[Main] Japanese words cleanup completed');
      
      // 熟語を削除（一度だけ実行）
      print('[Main] Cleaning up phrases...');
      await StorageService.deletePhrases();
      print('[Main] Phrases cleanup completed');
      
      // サンプルデータの初期化は削除（本番環境では不要）
      // print('[Main] Initializing sample data...');
      // await StorageService.initializeSampleData();
      // print('[Main] Sample data initialized successfully');
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
      
      // アプリ起動時にデータ同期を実行
      if (SupabaseService.isAvailable) {
        print('[Main] Starting data synchronization...');
        await _performInitialDataSync();
        print('[Main] Data synchronization completed');
      }
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

// アプリ起動時のデータ同期処理
Future<void> _performInitialDataSync() async {
  try {
    print('[Sync] Starting initial data synchronization...');
    
    // Supabaseからデータを取得して、ローカルと同期
    // この処理は既にStorageService.getDiaryEntries()とgetWords()で実装済み
    final diaryEntries = await StorageService.getDiaryEntries();
    final words = await StorageService.getWords();
    
    print('[Sync] Synchronized ${diaryEntries.length} diary entries and ${words.length} words');
  } catch (e) {
    print('[Sync] Error during initial synchronization: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider.instance;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

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
      darkTheme: AppTheme.darkTheme.copyWith(
        // 包括的なフォントフォールバックを追加
        textTheme: AppTheme.darkTheme.textTheme.apply(
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
      themeMode: _themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}