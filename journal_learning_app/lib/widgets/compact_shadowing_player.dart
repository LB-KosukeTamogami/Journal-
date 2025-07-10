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
  double _currentPosition = 0;
  double _totalDuration = 100;
  double _playbackSpeed = 1.0;
  bool _showSpeedOptions = false;
  
  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _estimateDuration();
  }
  
  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }
  
  void _estimateDuration() {
    final wordCount = widget.text.split(' ').length;
    _totalDuration = (wordCount * 0.5).clamp(1, 300);
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
    });
    
    await _ttsService.setSpeechRate(_playbackSpeed);
    await _ttsService.speak(widget.text);
    
    _updateProgress();
  }
  
  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
    });
    
    await _ttsService.stop();
  }
  
  void _updateProgress() {
    if (!_isPlaying) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_isPlaying) return;
      
      setState(() {
        _currentPosition += (0.1 / _playbackSpeed);
        if (_currentPosition >= _totalDuration) {
          _currentPosition = _totalDuration;
          _isPlaying = false;
        }
      });
      
      if (_isPlaying && _currentPosition < _totalDuration) {
        _updateProgress();
      }
    });
  }
  
  void _onSeek(double value) {
    setState(() {
      _currentPosition = value;
    });
  }
  
  void _seekForward() {
    setState(() {
      _currentPosition = (_currentPosition + 5).clamp(0, _totalDuration);
    });
  }
  
  void _seekBackward() {
    setState(() {
      _currentPosition = (_currentPosition - 5).clamp(0, _totalDuration);
    });
  }
  
  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    
    if (_isPlaying) {
      _ttsService.setSpeechRate(speed);
    }
  }
  
  String _formatTime(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
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
                // Progress bar at the very top
                Container(
                  height: 4,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.borderColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0, // Hide thumb for cleaner look
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 0,
                      ),
                    ),
                    child: Slider(
                      value: _currentPosition,
                      min: 0,
                      max: _totalDuration,
                      onChanged: _onSeek,
                    ),
                  ),
                ),
                
                // Main controls
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
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
                  
                  // Center controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 5 seconds backward
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: IconButton(
                          onPressed: _seekBackward,
                          icon: Icon(
                            Icons.replay_5,
                            color: AppTheme.textPrimary,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Play/Pause button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 5 seconds forward
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: IconButton(
                          onPressed: _seekForward,
                          icon: Icon(
                            Icons.forward_5,
                            color: AppTheme.textPrimary,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Time display and close button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_formatTime(_currentPosition)} / ${_formatTime(_totalDuration)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
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
                ],
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 1, end: 0);
  }
  
  Widget _buildSpeedOption(double speed) {
    final isSelected = _playbackSpeed == speed;
    
    return InkWell(
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
    );
  }
}