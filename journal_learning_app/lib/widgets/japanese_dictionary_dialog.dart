import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/japanese_wordnet_service.dart';

class JapaneseDictionaryDialog extends StatefulWidget {
  final String word;

  const JapaneseDictionaryDialog({
    super.key,
    required this.word,
  });

  @override
  State<JapaneseDictionaryDialog> createState() => _JapaneseDictionaryDialogState();
}

class _JapaneseDictionaryDialogState extends State<JapaneseDictionaryDialog> {
  bool _isLoading = true;
  WordNetEntry? _wordNetEntry;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadDictionaryData();
  }

  Future<void> _loadDictionaryData() async {
    final result = await JapaneseWordNetService.lookupWord(widget.word);
    
    if (mounted) {
      setState(() {
        _wordNetEntry = result;
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(
                child: DictionaryCard(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '辞書を検索中...',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _wordNetEntry == null
                ? Center(
                    child: DictionaryCard(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'この単語の意味は見つかりませんでした',
                            style: AppTheme.body1.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '「${widget.word}」',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '閉じる',
                              style: AppTheme.body2.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
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
                      child: DictionaryCard(
                        key: ValueKey(_isFlipped),
                        padding: const EdgeInsets.all(32),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(
                                minHeight: 300,
                                maxWidth: 400,
                              ),
                              child: AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                firstChild: _buildCardFront(),
                                secondChild: _buildCardBack(),
                                crossFadeState: _isFlipped
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                              ),
                            ),
                            // 閉じるボタン
                            Positioned(
                              right: -8,
                              top: -8,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
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
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.touch_app,
                                    color: AppTheme.primaryColor,
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
    );
  }

  Widget _buildCardFront() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 品詞バッジ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.info.withOpacity(0.3),
            ),
          ),
          child: Text(
            _wordNetEntry!.partOfSpeech,
            style: AppTheme.body2.copyWith(
              color: AppTheme.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'English',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _wordNetEntry!.word,
          style: AppTheme.headline1.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flip,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'タップして意味を見る',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '日本語',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // 日本語の意味
          if (_wordNetEntry!.definitions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: _wordNetEntry!.definitions.map((def) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      def,
                      style: AppTheme.headline2.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ).toList(),
              ),
            ),
          ],
          // 例文
          if (_wordNetEntry!.examples.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '例文',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._wordNetEntry!.examples.take(2).map((example) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        example,
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
          ],
          // 同義語
          if (_wordNetEntry!.synonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '類義語',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _wordNetEntry!.synonyms
                  .take(4)
                  .map((synonym) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundTertiary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          synonym,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class DictionaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const DictionaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppTheme.backgroundPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}