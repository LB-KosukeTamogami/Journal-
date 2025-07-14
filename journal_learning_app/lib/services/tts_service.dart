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
  bool _userInteractionDone = false;

  // 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('[TTS] Initializing TTS Service...');
      
      // SpeechSynthesis APIの可用性をチェック
      if (html.window.speechSynthesis != null) {
        print('[TTS] SpeechSynthesis API is available');
        _isInitialized = true;
        
        // 音声リストを事前に読み込み
        _loadVoices();
        
        print('[TTS] TTS Service initialized successfully');
      } else {
        print('[TTS] SpeechSynthesis API is not available');
      }
    } catch (e) {
      print('[TTS] Initialization error: $e');
    }
  }

  // 音声リストを読み込む
  void _loadVoices() {
    try {
      final voices = html.window.speechSynthesis!.getVoices();
      print('[TTS] Loaded ${voices.length} voices');
      
      // 利用可能な音声をログ出力
      for (var voice in voices.take(5)) {
        print('[TTS] Voice: ${voice.name} (${voice.lang})');
      }
    } catch (e) {
      print('[TTS] Error loading voices: $e');
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
    print('[TTS] Speak called with text: "$text"');
    
    if (!_isInitialized) {
      print('[TTS] Not initialized, initializing...');
      await initialize();
    }

    if (html.window.speechSynthesis == null) {
      print('[TTS] SpeechSynthesis not available');
      return;
    }

    // 既に読み上げ中の場合は停止
    if (_isSpeaking) {
      print('[TTS] Already speaking, stopping...');
      await stop();
    }

    // テキストが空の場合は何もしない
    if (text.trim().isEmpty) {
      print('[TTS] Empty text, skipping');
      return;
    }

    try {
      // 言語を自動検出
      String language = _detectLanguage(text);
      print('[TTS] Detected language: $language');
      
      // 既存の発話を確実に停止
      html.window.speechSynthesis!.cancel();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // SpeechSynthesisUtterance を作成
      final utterance = html.SpeechSynthesisUtterance(text);
      
      // 基本設定
      utterance.lang = language;
      utterance.rate = _speechRate;
      utterance.pitch = _pitch;
      utterance.volume = 1.0;
      
      print('[TTS] Created utterance with settings: lang=$language, rate=$_speechRate, pitch=$_pitch');
      
      // 適切な音声を選択
      final voices = html.window.speechSynthesis!.getVoices();
      for (var voice in voices) {
        if (voice.lang?.startsWith(language.substring(0, 2)) == true) {
          utterance.voice = voice;
          print('[TTS] Selected voice: ${voice.name} (${voice.lang})');
          break;
        }
      }
      
      // イベントハンドラーを設定
      utterance.onStart.listen((_) {
        print('[TTS] Speech started: "$text"');
        _isSpeaking = true;
        _speakStartTime = DateTime.now();
      });
      
      utterance.onEnd.listen((_) {
        print('[TTS] Speech ended: "$text"');
        _isSpeaking = false;
        _speakStartTime = null;
        _progressHandler?.call(1.0);
      });
      
      utterance.onError.listen((event) {
        print('[TTS] Speech error: $event');
        _isSpeaking = false;
        _speakStartTime = null;
      });
      
      // ユーザーインタラクションを一度確保
      if (!_userInteractionDone) {
        print('[TTS] Ensuring user interaction...');
        await _ensureUserInteraction();
      }
      
      // 読み上げ開始
      print('[TTS] Starting speech synthesis...');
      html.window.speechSynthesis!.speak(utterance);
      
      // 少し待って開始を確認
      await Future.delayed(const Duration(milliseconds: 200));
      
      final isSpeaking = html.window.speechSynthesis!.speaking ?? false;
      if (!_isSpeaking && !isSpeaking) {
        print('[TTS] Speech failed to start, trying again...');
        // 再試行
        html.window.speechSynthesis!.speak(utterance);
        await Future.delayed(const Duration(milliseconds: 200));
        
        final isRetrySuccess = html.window.speechSynthesis!.speaking ?? false;
        if (!_isSpeaking && !isRetrySuccess) {
          print('[TTS] Speech failed to start after retry');
        } else {
          print('[TTS] Speech started successfully on retry');
        }
      } else {
        print('[TTS] Speech started successfully');
      }
      
    } catch (e, stack) {
      print('[TTS] Error in speak method: $e');
      print('[TTS] Stack trace: $stack');
      _isSpeaking = false;
    }
  }

  // ユーザーインタラクションを確保
  Future<void> _ensureUserInteraction() async {
    try {
      print('[TTS] Ensuring user interaction...');
      
      if (html.window.speechSynthesis == null) {
        print('[TTS] SpeechSynthesis not available for user interaction');
        return;
      }
      
      // 無音の短い発話でユーザーインタラクションを確立
      final testUtterance = html.SpeechSynthesisUtterance(' ');
      testUtterance.volume = 0.01;
      testUtterance.rate = 10.0; // 非常に速く
      
      html.window.speechSynthesis!.speak(testUtterance);
      await Future.delayed(const Duration(milliseconds: 100));
      html.window.speechSynthesis!.cancel();
      
      _userInteractionDone = true;
      print('[TTS] User interaction established');
    } catch (e) {
      print('[TTS] User interaction setup error: $e');
    }
  }

  // 読み上げを停止
  Future<void> stop() async {
    print('[TTS] Stop called');
    
    try {
      if (html.window.speechSynthesis != null) {
        html.window.speechSynthesis!.cancel();
        print('[TTS] Speech cancelled');
      }
      _isSpeaking = false;
      _speakStartTime = null;
    } catch (e) {
      print('[TTS] Error stopping speech: $e');
    }
  }

  // 読み上げ中かどうか
  bool get isSpeaking => _isSpeaking;

  // 速度を設定（0.0 - 1.0）
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    print('[TTS] Speech rate set to: $_speechRate');
  }

  // ピッチを設定（0.5 - 2.0）
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    print('[TTS] Pitch set to: $_pitch');
  }

  // 言語を手動設定
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    print('[TTS] Language set to: $languageCode');
  }

  // リソースを解放
  void dispose() {
    print('[TTS] Disposing TTS service');
    try {
      if (html.window.speechSynthesis != null) {
        html.window.speechSynthesis!.cancel();
      }
    } catch (e) {
      print('[TTS] Error during disposal: $e');
    }
    _isInitialized = false;
    _isSpeaking = false;
    _progressHandler = null;
    _userInteractionDone = false;
  }

  // プログレスハンドラーを設定
  void setProgressHandler(Function(double) handler) {
    _progressHandler = handler;
    print('[TTS] Progress handler set');
  }

  // プログレスハンドラーを解除
  void removeProgressHandler() {
    _progressHandler = null;
    print('[TTS] Progress handler removed');
  }

  // デバッグ用: TTS状態を取得
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isSpeaking': _isSpeaking,
      'userInteractionDone': _userInteractionDone,
      'speechRate': _speechRate,
      'pitch': _pitch,
      'language': _language,
      'apiAvailable': html.window.speechSynthesis != null,
      'voicesCount': html.window.speechSynthesis?.getVoices().length ?? 0,
    };
  }
}