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
    return Container(
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar at the top
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.borderColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: _currentPosition,
                      min: 0,
                      max: _totalDuration,
                      onChanged: _onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentPosition),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatTime(_totalDuration),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speed control
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactSpeedButton('0.5', 0.5),
                        const SizedBox(width: 2),
                        _buildCompactSpeedButton('0.75', 0.75),
                        const SizedBox(width: 2),
                        _buildCompactSpeedButton('1.0', 1.0),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 5 seconds backward
                  Container(
                    width: 36,
                    height: 36,
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
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Play/Pause button
                  Container(
                    width: 44,
                    height: 44,
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
                  
                  const SizedBox(width: 8),
                  
                  // 5 seconds forward
                  Container(
                    width: 36,
                    height: 36,
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
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  const Spacer(),
                  
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
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 1, end: 0);
  }
  
  Widget _buildCompactSpeedButton(String label, double speed) {
    final isSelected = _playbackSpeed == speed;
    
    return GestureDetector(
      onTap: () => _changeSpeed(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}