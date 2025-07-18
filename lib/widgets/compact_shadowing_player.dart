import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class CompactShadowingPlayer extends StatefulWidget {
  final String text;
  final VoidCallback onClose;
  
  const CompactShadowingPlayer({
    super.key,
    required this.text,
    required this.onClose,
  });

  @override
  State<CompactShadowingPlayer> createState() => _CompactShadowingPlayerState();
}

class _CompactShadowingPlayerState extends State<CompactShadowingPlayer> {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _showSpeedOptions = false;
  double _totalDuration = 0;
  double _currentTime = 0;
  DateTime? _startTime;
  
  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _ttsService.setDurationHandler((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _stopPlayback();
    _ttsService.removeDurationHandler();
    super.dispose();
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
      _startTime = DateTime.now();
      _currentTime = 0;
    });
    
    await _ttsService.setSpeechRate(_playbackSpeed);
    await _ttsService.speak(widget.text);
    
    // 再生終了を監視
    _checkPlaybackStatus();
    // 時間更新を開始
    _updateTime();
  }
  
  void _checkPlaybackStatus() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (!_ttsService.isSpeaking && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _startTime = null;
        });
      } else if (_isPlaying) {
        _checkPlaybackStatus();
      }
    });
  }
  
  void _updateTime() {
    if (!_isPlaying || _startTime == null) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_isPlaying) return;
      
      setState(() {
        _currentTime = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
      });
      
      _updateTime();
    });
  }
  
  String _formatTime(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
  
  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
      _startTime = null;
      _currentTime = 0;
    });
    
    await _ttsService.stop();
  }
  
  
  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _showSpeedOptions = false;
    });
    
    if (_isPlaying) {
      // 再生中の場合は一旦停止して、新しい速度で再生し直す
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                  // Speed control (dropdown style)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSpeedOptions = !_showSpeedOptions;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_playbackSpeed}x',
                            style: AppTheme.body2.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showSpeedOptions ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Play/Pause button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _togglePlayback,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Time display
                  if (_isPlaying || _totalDuration > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _totalDuration > 0 
                          ? '${_formatTime(_currentTime)} / ${_formatTime(_totalDuration)}'
                          : _formatTime(_currentTime),
                        style: AppTheme.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 12),
                  
                  // Close button
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
          // Speed options popup (shown above the player when open)
          if (_showSpeedOptions)
            Positioned(
              bottom: 70,
              left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSpeedOption(0.5),
                  _buildSpeedOption(0.75),
                  _buildSpeedOption(1.0),
                  _buildSpeedOption(1.25),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 1, end: 0);
  }
  
  Widget _buildSpeedOption(double speed) {
    final isSelected = _playbackSpeed == speed;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _changeSpeed(speed);
          setState(() {
            _showSpeedOptions = false;
          });
        },
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          ),
          child: Text(
            '${speed}x',
            style: AppTheme.body2.copyWith(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}