import 'package:flutter/material.dart';

class TextToSpeechButton extends StatefulWidget {
  final String text;
  final String language;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final double? size;
  
  const TextToSpeechButton({
    super.key,
    required this.text,
    this.language = 'en-US',
    this.onPlay,
    this.onStop,
    this.size,
  });

  @override
  State<TextToSpeechButton> createState() => _TextToSpeechButtonState();
}

class _TextToSpeechButtonState extends State<TextToSpeechButton> {
  bool _isPlaying = false;
  
  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      widget.onPlay?.call();
      // Simulate playback completion after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } else {
      widget.onStop?.call();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isPlaying ? Icons.stop : Icons.volume_up,
        color: Theme.of(context).colorScheme.primary,
        size: widget.size,
      ),
      onPressed: widget.text.isNotEmpty ? _togglePlayback : null,
      tooltip: _isPlaying ? '停止' : '音声再生',
    );
  }
}