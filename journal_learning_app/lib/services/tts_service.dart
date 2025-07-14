import 'dart:html' as html;
import 'dart:js' as js;

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  Function(double)? _progressHandler;
  DateTime? _speakStartTime;
  int _totalCharacters = 0;
  double _speechRate = 0.9;
  double _pitch = 1.0;
  String? _language;

  // 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // HTML5 SpeechSynthesis API が利用可能かチェック
      if (js.context['speechSynthesis'] != null) {
        print('HTML5 SpeechSynthesis API is available');
        _isInitialized = true;
      } else {
        print('HTML5 SpeechSynthesis API is not available');
      }
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
      // 言語を自動検出
      String language = _detectLanguage(textToSpeak);
      
      _totalCharacters = textToSpeak.length;
      print('Speaking in $language: $textToSpeak (${_totalCharacters} characters)');
      
      // HTML5 SpeechSynthesis API を使用
      final speechSynthesis = js.context['speechSynthesis'];
      if (speechSynthesis != null) {
        // 既存の発話を停止
        speechSynthesis.callMethod('cancel');
        
        // SpeechSynthesisUtterance を作成
        final utterance = js.context['SpeechSynthesisUtterance'].callMethod('constructor', [textToSpeak]);
        
        // 言語設定
        utterance['lang'] = _language ?? language;
        utterance['rate'] = _speechRate;
        utterance['pitch'] = _pitch;
        utterance['volume'] = 1.0;
        
        // イベントハンドラーを設定
        utterance['onstart'] = js.allowInterop((_) {
          _isSpeaking = true;
          _speakStartTime = DateTime.now();
          _startProgressTracking();
        });
        
        utterance['onend'] = js.allowInterop((_) {
          _isSpeaking = false;
          _speakStartTime = null;
          _progressHandler?.call(1.0);
        });
        
        utterance['onerror'] = js.allowInterop((event) {
          _isSpeaking = false;
          _speakStartTime = null;
          print('TTS Error: $event');
        });
        
        // 読み上げ開始
        speechSynthesis.callMethod('speak', [utterance]);
        print('HTML5 TTS started successfully');
      } else {
        print('SpeechSynthesis API is not available');
      }
    } catch (e) {
      print('TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  // 読み上げを停止
  Future<void> stop() async {
    if (_isSpeaking) {
      final speechSynthesis = js.context['speechSynthesis'];
      if (speechSynthesis != null) {
        speechSynthesis.callMethod('cancel');
      }
      _isSpeaking = false;
    }
  }

  // 読み上げ中かどうか
  bool get isSpeaking => _isSpeaking;

  // 速度を設定（0.0 - 1.0）
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    print('Speech rate set to: $rate');
  }

  // ピッチを設定（0.5 - 2.0）
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    print('Pitch set to: $pitch');
  }

  // 言語を手動設定
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    print('Language set to: $languageCode');
  }

  // リソースを解放
  void dispose() {
    final speechSynthesis = js.context['speechSynthesis'];
    if (speechSynthesis != null) {
      speechSynthesis.callMethod('cancel');
    }
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