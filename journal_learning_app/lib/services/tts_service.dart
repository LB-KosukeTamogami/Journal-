import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  Function(double)? _progressHandler;
  DateTime? _speakStartTime;
  int _totalCharacters = 0;

  // 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 基本設定
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.9); // 少し遅めに設定
      await _flutterTts.setPitch(1.0);

      // Webプラットフォーム対応
      await _flutterTts.awaitSpeakCompletion(true);

      // 利用可能な言語を取得
      List<dynamic> languages = await _flutterTts.getLanguages;
      print('Available TTS languages: $languages');

      // コールバック設定
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakStartTime = DateTime.now();
        _startProgressTracking();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakStartTime = null;
        _progressHandler?.call(1.0);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _speakStartTime = null;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakStartTime = null;
        print('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  // 言語を検出
  String _detectLanguage(String text) {
    // 日本語の文字（ひらがな、カタカナ、漢字）が含まれているかチェック
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japanesePattern.hasMatch(text) ? 'ja-JP' : 'en-US';
  }

  // テキストを読み上げる
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 既に読み上げ中の場合は停止
    if (_isSpeaking) {
      await stop();
    }

    // テキストが空の場合は何もしない
    if (text.trim().isEmpty) return;

    // 最大200文字に制限
    String textToSpeak = text;
    if (text.length > 200) {
      textToSpeak = text.substring(0, 200);
    }

    try {
      // 言語を自動検出して設定
      String language = _detectLanguage(textToSpeak);
      await _flutterTts.setLanguage(language);
      
      _totalCharacters = textToSpeak.length;
      print('Speaking in $language: $textToSpeak (${_totalCharacters} characters)');
      
      // 読み上げ実行
      var result = await _flutterTts.speak(textToSpeak);
      if (result == 1) {
        print('TTS started successfully');
      } else {
        print('TTS failed to start');
      }
    } catch (e) {
      print('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  // 読み上げを停止
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  // 読み上げ中かどうか
  bool get isSpeaking => _isSpeaking;

  // 言語を手動設定
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.setLanguage(languageCode);
  }

  // 速度を設定（0.0 - 1.0）
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.setSpeechRate(rate);
  }

  // ピッチを設定（0.5 - 2.0）
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.setPitch(pitch);
  }

  // リソースを解放
  void dispose() {
    _flutterTts.stop();
    _isInitialized = false;
    _isSpeaking = false;
    _progressHandler = null;
  }

  // プログレスハンドラーを設定
  void setProgressHandler(Function(double) handler) {
    _progressHandler = handler;
  }

  // プログレスハンドラーを解除
  void removeProgressHandler() {
    _progressHandler = null;
  }

  // プログレストラッキングを開始
  void _startProgressTracking() {
    if (_speakStartTime == null || _totalCharacters == 0) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isSpeaking || _speakStartTime == null) return;
      
      // 推定進行率を計算（1文字あたり約0.15秒と仮定）
      final elapsed = DateTime.now().difference(_speakStartTime!).inMilliseconds / 1000.0;
      final estimatedDuration = _totalCharacters * 0.15;
      final progress = (elapsed / estimatedDuration).clamp(0.0, 1.0);
      
      _progressHandler?.call(progress);
      
      if (_isSpeaking && progress < 1.0) {
        _startProgressTracking();
      }
    });
  }
}