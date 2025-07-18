import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class IntegratedShadowingPlayer extends StatefulWidget {
  final String text;
  final VoidCallback onClose;
  final Function(String, int, double)? onWordHighlight;
  
  const IntegratedShadowingPlayer({
    super.key,
    required this.text,
    required this.onClose,
    this.onWordHighlight,
  });

  @override
  State<IntegratedShadowingPlayer> createState() => _IntegratedShadowingPlayerState();
}

class _IntegratedShadowingPlayerState extends State<IntegratedShadowingPlayer> {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;
  String _playbackMode = 'normal'; // 'normal' or 'word_by_word'
  List<String> _words = [];
  int _currentWordIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _initializeText();
    
    // 単語境界ハンドラーを設定
    _ttsService.setWordBoundaryHandler((word, index, elapsedTime) {
      if (mounted && _playbackMode == 'word_by_word') {
        setState(() {
          _currentWordIndex = index;
        });
        // 外部にハイライト情報を通知
        widget.onWordHighlight?.call(word, index, elapsedTime);
      }
    });
  }
  
  @override
  void dispose() {
    _stopPlayback();
    _ttsService.removeWordBoundaryHandler();
    super.dispose();
  }
  
  void _initializeText() {
    _words = widget.text.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }
  
  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }
  
  Future<void> _startPlayback() async {
    setState(() {
      _isPlaying = true;
      _currentWordIndex = -1;
    });
    
    await _ttsService.speak(widget.text);
    
    // 再生終了を監視
    _checkPlaybackStatus();
  }
  
  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
      _currentWordIndex = -1;
    });
    
    await _ttsService.stop();
    // ハイライトをクリア
    widget.onWordHighlight?.call('', -1, 0);
  }
  
  void _checkPlaybackStatus() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (!_ttsService.isSpeaking && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _currentWordIndex = -1;
        });
        // ハイライトをクリア
        widget.onWordHighlight?.call('', -1, 0);
      } else if (_isPlaying) {
        _checkPlaybackStatus();
      }
    });
  }
  
  void _changeMode(String mode) {
    setState(() {
      _playbackMode = mode;
    });
    
    if (_isPlaying) {
      // 再生中の場合は一旦停止して、新しいモードで再生し直す
      _stopPlayback().then((_) {
        _startPlayback();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main controls
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // 速度・モード選択
                        // モード選択ボタン
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModeButton('normal', '標準', Icons.play_arrow),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppTheme.borderColor,
                              ),
                              _buildModeButton('word_by_word', '単語', Icons.text_fields),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // 再生/停止ボタン
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _togglePlayback,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // 閉じるボタン
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 1, end: 0);
  }
  
  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isSelected = _playbackMode == mode;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeMode(mode),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.body2.copyWith(
                  fontSize: 12,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}