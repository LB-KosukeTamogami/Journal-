import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class ShadowingPlayer extends StatefulWidget {
  final String text;
  final String title;
  
  const ShadowingPlayer({
    super.key,
    required this.text,
    required this.title,
  });

  static void show(BuildContext context, String text, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShadowingPlayer(
        text: text,
        title: title,
      ),
    );
  }

  @override
  State<ShadowingPlayer> createState() => _ShadowingPlayerState();
}

class _ShadowingPlayerState extends State<ShadowingPlayer> with SingleTickerProviderStateMixin {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;
  double _currentPosition = 0;
  double _totalDuration = 100;
  double _playbackSpeed = 1.0;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _ttsService.initialize();
    _estimateDuration();
  }
  
  @override
  void dispose() {
    _stopPlayback();
    _animationController.dispose();
    super.dispose();
  }
  
  void _estimateDuration() {
    // Estimate duration based on text length (rough approximation)
    final wordCount = widget.text.split(' ').length;
    _totalDuration = (wordCount * 0.5).clamp(1, 300); // 0.5 seconds per word
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
    
    // Set speech rate
    await _ttsService.setSpeechRate(_playbackSpeed);
    
    // Start animation
    _animationController.forward();
    
    // Play the text
    await _ttsService.speak(widget.text);
    
    // Simulate progress updates
    _updateProgress();
  }
  
  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
    });
    
    await _ttsService.stop();
    _animationController.reverse();
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
          _animationController.reverse();
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
    
    // In a real implementation, you would seek the TTS to this position
    // For now, we just update the UI
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTheme.headline3,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Playback controls
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isPlaying 
                        ? AppTheme.primaryColor.withOpacity(0.05)
                        : AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isPlaying 
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Play/Pause button
                      Center(
                        child: Material(
                          color: AppTheme.primaryColor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _togglePlayback,
                            customBorder: const CircleBorder(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 64,
                              height: 64,
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ).animate(target: _isPlaying ? 1 : 0)
                        .scale(begin: 1, end: 1.1, duration: 300.ms)
                        .then()
                        .scale(begin: 1.1, end: 1, duration: 300.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Progress bar
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor: AppTheme.borderColor,
                              thumbColor: AppTheme.primaryColor,
                              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_currentPosition),
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  _formatTime(_totalDuration),
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Speed controls
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundPrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '再生速度',
                              style: AppTheme.body2.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildSpeedButton('0.75x', 0.75),
                            const SizedBox(width: 8),
                            _buildSpeedButton('標準', 1.0),
                            const SizedBox(width: 8),
                            _buildSpeedButton('1.25x', 1.25),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Text display
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      child: Text(
                        widget.text,
                        style: AppTheme.body1.copyWith(
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildSpeedButton(String label, double speed) {
    final isSelected = _playbackSpeed == speed;
    
    return Material(
      color: isSelected 
          ? AppTheme.primaryColor 
          : AppTheme.backgroundSecondary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _changeSpeed(speed),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: AppTheme.body2.copyWith(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}