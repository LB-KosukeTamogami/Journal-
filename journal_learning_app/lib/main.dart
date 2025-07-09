import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .envファイルを読み込む
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found or could not be loaded: $e');
  }
  
  await StorageService.init();
  await StorageService.initializeSampleData();
  runApp(const MyApp());
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