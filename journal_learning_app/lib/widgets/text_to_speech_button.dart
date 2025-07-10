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
    if (_isSpeaking) {
      // 読み上げ中の場合は停止
      await _ttsService.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      // アニメーション実行
      await _animationController.forward();
      await _animationController.reverse();

      // 読み上げ開始
      setState(() {
        _isSpeaking = true;
      });

      await _ttsService.speak(widget.text);

      // 読み上げ完了を待つ
      // TTSサービスのコールバックで状態が更新されるまで待機
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_ttsService.isSpeaking) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      // 長いテキストの場合は定期的にチェック
      while (_ttsService.isSpeaking && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _isSpeaking = _ttsService.isSpeaking;
          });
        }
      }
    }
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
          onPressed: _isSpeaking || widget.text.isEmpty ? null : _handlePress,
          tooltip: _isSpeaking ? '停止' : '読み上げ',
        ),
      ),
    );
  }
}