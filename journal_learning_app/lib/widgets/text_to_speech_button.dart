import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class TextToSpeechButton extends StatefulWidget {
  final String text;
  final double? size;
  final Color? color;
  final Color? backgroundColor;
  
  const TextToSpeechButton({
    super.key,
    required this.text,
    this.size,
    this.color,
    this.backgroundColor,
  });

  @override
  State<TextToSpeechButton> createState() => _TextToSpeechButtonState();
}

class _TextToSpeechButtonState extends State<TextToSpeechButton> with SingleTickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  bool _isSpeaking = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // TTSサービスを初期化
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    print('[TTS Button] Button pressed for text: "${widget.text}"');
    
    if (_isSpeaking) {
      // 読み上げ中の場合は停止
      print('[TTS Button] Stopping current speech');
      await _ttsService.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    try {
      // アニメーション実行
      await _animationController.forward();
      await _animationController.reverse();

      // 読み上げ開始
      print('[TTS Button] Starting speech for: "${widget.text}"');
      setState(() {
        _isSpeaking = true;
      });

      // TTSサービスの状態をログ出力
      final status = _ttsService.getStatus();
      print('[TTS Button] TTS Service status: $status');

      await _ttsService.speak(widget.text);

      // 読み上げ状態の監視
      _monitorSpeechStatus();

    } catch (e) {
      print('[TTS Button] Error during speech: $e');
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  void _monitorSpeechStatus() {
    // 定期的に読み上げ状態をチェック
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final isSpeaking = _ttsService.isSpeaking;
        print('[TTS Button] Speech status check: $isSpeaking');
        
        if (_isSpeaking != isSpeaking) {
          setState(() {
            _isSpeaking = isSpeaking;
          });
        }
        
        // まだ読み上げ中の場合は継続監視
        if (isSpeaking) {
          _monitorSpeechStatus();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSpeaking
                ? Icon(
                    Icons.stop,
                    key: const ValueKey('stop'),
                    color: widget.color ?? AppTheme.error,
                    size: widget.size ?? 24,
                  )
                : Icon(
                    Icons.volume_up,
                    key: const ValueKey('volume'),
                    color: widget.color ?? AppTheme.primaryBlue,
                    size: widget.size ?? 24,
                  ),
          ),
          onPressed: widget.text.isEmpty ? null : _handlePress,
          tooltip: _isSpeaking ? '停止' : '読み上げ',
        ),
      ),
    );
  }
}