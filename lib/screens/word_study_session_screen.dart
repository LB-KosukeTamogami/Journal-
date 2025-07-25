import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/text_to_speech_button.dart';

class WordStudySessionScreen extends StatefulWidget {
  final List<Word> words;

  const WordStudySessionScreen({
    super.key,
    required this.words,
  });

  @override
  State<WordStudySessionScreen> createState() => _WordStudySessionScreenState();
}

class _WordStudySessionScreenState extends State<WordStudySessionScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _showResult = false;
  int _masteredCount = 0;
  int _partialCount = 0;
  int _unknownCount = 0;
  int _totalCount = 0;
  bool _isAudioEnabled = true;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    // 最初のカードの音声を自動再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAudioEnabled && widget.words.isNotEmpty) {
        _playCurrentCardAudio();
      }
    });
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Future<void> _playCurrentCardAudio() async {
    if (!_isAudioEnabled || _isPlayingAudio || _currentIndex >= widget.words.length) return;
    
    setState(() {
      _isPlayingAudio = true;
    });
    
    final currentWord = widget.words[_currentIndex];
    // TextToSpeechButtonの機能を直接使用
    await TTSService().speak(currentWord.english);
    
    setState(() {
      _isPlayingAudio = false;
    });
  }

  void _nextCard({required int masteryLevel}) {
    // masteryLevel: 2 = ○ (mastered), 1 = △ (partial), 0 = × (unknown)
    
    // Update word mastery in storage
    final currentWord = widget.words[_currentIndex];
    _updateWordMastery(currentWord, masteryLevel);
    
    setState(() {
      _totalCount++;
      switch (masteryLevel) {
        case 2:
          _masteredCount++;
          break;
        case 1:
          _partialCount++;
          break;
        case 0:
          _unknownCount++;
          break;
      }
      
      if (_currentIndex < widget.words.length - 1) {
        _currentIndex++;
        _isFlipped = false;
        // 次のカードの音声を自動再生
        if (_isAudioEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _playCurrentCardAudio();
          });
        }
      } else {
        _finishReview();
      }
    });
  }

  void _finishReview() {
    setState(() {
      _showResult = true;
    });
  }

  void _resetReview() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _showResult = false;
      _masteredCount = 0;
      _partialCount = 0;
      _unknownCount = 0;
      _totalCount = 0;
    });
    
    // リセット後、音声が有効な場合は最初のカードの音声を再生
    if (_isAudioEnabled && widget.words.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playCurrentCardAudio();
      });
    }
  }

  void _updateWordMastery(Word word, int masteryLevel) async {
    await StorageService.updateWordReview(word.id, masteryLevel: masteryLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('フラッシュカード学習', style: AppTheme.headline3),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAudioEnabled ? Icons.volume_up : Icons.volume_off,
              color: _isAudioEnabled ? AppTheme.primaryBlue : AppTheme.textTertiary,
            ),
            onPressed: () {
              setState(() {
                _isAudioEnabled = !_isAudioEnabled;
              });
              if (_isAudioEnabled) {
                // 音声をONにしたら現在のカードの音声を再生
                _playCurrentCardAudio();
              }
            },
          ),
        ],
      ),
      body: _showResult ? _buildResultScreen() : _buildFlashcardScreen(),
    );
  }

  Widget _buildFlashcardScreen() {
    final currentWord = widget.words[_currentIndex];
    final progress = (_currentIndex + 1) / widget.words.length;

    return Column(
      children: [
        // プログレスバー
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${widget.words.length}',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_totalCount > 0)
                    Row(
                      children: [
                        Text('○', style: AppTheme.body2.copyWith(color: AppTheme.success)),
                        Text(':$_masteredCount ', style: AppTheme.caption),
                        const SizedBox(width: 8),
                        Text('△', style: AppTheme.body2.copyWith(color: AppTheme.warning)),
                        Text(':$_partialCount ', style: AppTheme.caption),
                        const SizedBox(width: 8),
                        Text('×', style: AppTheme.body2.copyWith(color: AppTheme.error)),
                        Text(':$_unknownCount', style: AppTheme.caption),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ],
          ),
        ),

        // フラッシュカード
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: AppCard(
                    key: ValueKey(_isFlipped),
                    padding: const EdgeInsets.all(32),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 300,
                          alignment: Alignment.center,
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            firstChild: Center(child: _buildCardFront(currentWord)),
                            secondChild: Center(child: _buildCardBack(currentWord)),
                            crossFadeState: _isFlipped
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          ),
                        ),
                        // タップアイコンを右下に配置（表面のみ）
                        if (!_isFlipped)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.touch_app,
                                color: AppTheme.primaryBlue,
                                size: 24,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                              .fade(begin: 0.5, end: 1.0, duration: 1.2.seconds)
                              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.2.seconds),
                          ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ),

        // ボタン
        Container(
          padding: const EdgeInsets.all(20),
          child: _isFlipped
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(masteryLevel: 0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('×', style: AppTheme.headline3.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('未習得', style: AppTheme.caption.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(masteryLevel: 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('△', style: AppTheme.headline3.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('うろ覚え', style: AppTheme.caption.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(masteryLevel: 2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('○', style: AppTheme.headline3.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('習得済み', style: AppTheme.caption.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: (!_isAudioEnabled || _isPlayingAudio) ? null : _playCurrentCardAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAudioEnabled ? AppTheme.primaryBlue : Theme.of(context).colorScheme.surface,
                    foregroundColor: _isAudioEnabled ? Colors.white : AppTheme.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlayingAudio ? Icons.stop : Icons.volume_up,
                        color: _isAudioEnabled ? Colors.white : AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPlayingAudio ? '再生中...' : '音声を再生',
                        style: AppTheme.button.copyWith(
                          color: _isAudioEnabled ? Colors.white : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCardFront(Word word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '英語',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          word.english,
          style: AppTheme.headline1.copyWith(
            color: AppTheme.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'カードをタップして答えを確認',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(Word word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '日本語',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          word.japanese,
          style: AppTheme.headline1.copyWith(
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (word.example != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              word.example!,
              style: AppTheme.body2.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultScreen() {
    final masteryRate = _totalCount > 0 ? (_masteredCount / _totalCount) * 100 : 0;
    final isGoodResult = masteryRate >= 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGoodResult ? Icons.celebration : Icons.refresh,
              size: 64,
              color: isGoodResult ? AppTheme.success : AppTheme.warning,
            ),
            const SizedBox(height: 24),
            Text(
              '学習完了！',
              style: AppTheme.headline1,
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('学習した単語', style: AppTheme.body1),
                      Text('${widget.words.length}個', style: AppTheme.body1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('○ ', style: AppTheme.headline3.copyWith(color: AppTheme.success)),
                                Text('習得済み', style: AppTheme.body2),
                              ],
                            ),
                            Text('$_masteredCount個', style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('△ ', style: AppTheme.headline3.copyWith(color: AppTheme.warning)),
                                Text('うろ覚え', style: AppTheme.body2),
                              ],
                            ),
                            Text('$_partialCount個', style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('× ', style: AppTheme.headline3.copyWith(color: AppTheme.error)),
                                Text('未習得', style: AppTheme.body2),
                              ],
                            ),
                            Text('$_unknownCount個', style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('習得率', style: AppTheme.body1),
                      Text(
                        '${masteryRate.toStringAsFixed(0)}%',
                        style: AppTheme.body1.copyWith(
                          color: isGoodResult ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('もう一度', style: AppTheme.button),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('完了', style: AppTheme.button),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}