import 'dart:html' as html;
import 'dart:js' as js;

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  Function(double)? _progressHandler;
  Function(double)? _durationHandler;
  Function(String, int, double)? _wordBoundaryHandler;
  DateTime? _speakStartTime;
  int _totalCharacters = 0;
  double _speechRate = 0.9;
  double _pitch = 1.0;
  String? _language;
  bool _userInteractionDone = false;
  double _totalDuration = 0;
  String _currentText = '';
  List<String> _words = [];
  int _currentWordIndex = 0;

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
    
    // 単語分割の準備
    _currentText = text;
    _words = _splitTextIntoWords(text);
    _currentWordIndex = 0;
    print('[TTS] Text split into ${_words.length} words');

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
        _totalDuration = 0;
      });
      
      // boundary イベントで進行状況を追跡
      utterance.on['boundary'].listen((event) {
        try {
          // JavaScriptのイベントオブジェクトから情報を取得
          final jsEvent = js.JsObject.fromBrowserObject(event);
          final elapsedTime = jsEvent['elapsedTime'];
          final charIndex = jsEvent['charIndex'];
          final name = jsEvent['name'];
          
          if (elapsedTime != null) {
            final elapsed = (elapsedTime as num).toDouble();
            // Chrome はミリ秒、その他は秒で返すため調整
            final elapsedSeconds = elapsed > 100 ? elapsed / 1000 : elapsed;
            _totalDuration = elapsedSeconds;
            
            // 単語境界の場合、現在の単語を特定
            if (name == 'word' && charIndex != null) {
              final charIdx = (charIndex as num).toInt();
              final currentWord = _getCurrentWordAtIndex(charIdx);
              final wordIndex = _getWordIndexAtCharIndex(charIdx);
              
              print('[TTS] Word boundary - word: "$currentWord", index: $wordIndex, char: $charIdx, elapsed: ${elapsedSeconds}s');
              
              // 単語境界ハンドラーを呼び出し
              _wordBoundaryHandler?.call(currentWord, wordIndex, elapsedSeconds);
            }
            
            print('[TTS] Boundary event - type: $name, elapsed: ${elapsedSeconds}s');
          }
        } catch (e) {
          print('[TTS] Error in boundary event: $e');
        }
      });
      
      utterance.onEnd.listen((event) {
        try {
          // elapsedTime を取得
          final jsEvent = js.JsObject.fromBrowserObject(event);
          final elapsedTime = jsEvent['elapsedTime'];
          if (elapsedTime != null) {
            final elapsed = (elapsedTime as num).toDouble();
            // Chrome はミリ秒、その他は秒で返すため調整
            final totalSeconds = elapsed > 100 ? elapsed / 1000 : elapsed;
            _totalDuration = totalSeconds;
            print('[TTS] Speech ended - total duration: ${totalSeconds}s');
            _durationHandler?.call(totalSeconds);
          }
        } catch (e) {
          print('[TTS] Error getting elapsed time: $e');
        }
        
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
    _durationHandler = null;
    _wordBoundaryHandler = null;
    _userInteractionDone = false;
    _totalDuration = 0;
    _currentText = '';
    _words = [];
    _currentWordIndex = 0;
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
  
  // 再生時間ハンドラーの設定
  void setDurationHandler(Function(double) handler) {
    _durationHandler = handler;
  }
  
  // 再生時間ハンドラーの解除
  void removeDurationHandler() {
    _durationHandler = null;
  }
  
  // 単語境界ハンドラーの設定
  void setWordBoundaryHandler(Function(String, int, double) handler) {
    _wordBoundaryHandler = handler;
  }
  
  // 単語境界ハンドラーの解除
  void removeWordBoundaryHandler() {
    _wordBoundaryHandler = null;
  }
  
  // 現在の総再生時間を取得
  double get totalDuration => _totalDuration;
  
  // 現在の単語リストを取得
  List<String> get words => _words;
  
  // 現在の単語インデックスを取得
  int get currentWordIndex => _currentWordIndex;
  
  // テキストを単語に分割
  List<String> _splitTextIntoWords(String text) {
    // 句読点を考慮した単語分割
    return text.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }
  
  // 文字インデックスから現在の単語を取得
  String _getCurrentWordAtIndex(int charIndex) {
    try {
      int currentIndex = 0;
      for (int i = 0; i < _words.length; i++) {
        final word = _words[i];
        if (charIndex >= currentIndex && charIndex < currentIndex + word.length) {
          return word;
        }
        currentIndex += word.length + 1; // +1 for space
      }
      return '';
    } catch (e) {
      print('[TTS] Error getting current word: $e');
      return '';
    }
  }
  
  // 文字インデックスから単語インデックスを取得
  int _getWordIndexAtCharIndex(int charIndex) {
    try {
      int currentIndex = 0;
      for (int i = 0; i < _words.length; i++) {
        final word = _words[i];
        if (charIndex >= currentIndex && charIndex < currentIndex + word.length) {
          _currentWordIndex = i;
          return i;
        }
        currentIndex += word.length + 1; // +1 for space
      }
      return -1;
    } catch (e) {
      print('[TTS] Error getting word index: $e');
      return -1;
    }
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