import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart' show AppTheme, AppCard;
import '../services/japanese_wordnet_service.dart';

class JapaneseDictionaryDialog extends StatefulWidget {
  final String word;

  const JapaneseDictionaryDialog({
    super.key,
    required this.word,
  });

  static void show(BuildContext context, String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JapaneseDictionaryDialog(word: word),
    );
  }

  @override
  State<JapaneseDictionaryDialog> createState() => _JapaneseDictionaryDialogState();
}

class _JapaneseDictionaryDialogState extends State<JapaneseDictionaryDialog> {
  bool _isLoading = true;
  WordNetEntry? _wordNetEntry;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ハンドル
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
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
          else if (_wordNetEntry == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
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
                  ],
                ),
              ),
            )
          else ...[
            // 単語と品詞
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _wordNetEntry!.word,
                        style: AppTheme.headline2,
                      ),
                      const SizedBox(height: 8),
                      // 日本語の意味
                      if (_wordNetEntry!.definitions.isNotEmpty) ...[
                        Text(
                          _wordNetEntry!.definitions.join('、'),
                          style: AppTheme.body1.copyWith(fontSize: 18),
                        ),
                      ],
                    ],
                  ),
                ),
                // 品詞バッジ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _wordNetEntry!.partOfSpeech,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // 例文
            if (_wordNetEntry!.examples.isNotEmpty) ...[
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppTheme.backgroundTertiary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '例文',
                          style: AppTheme.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._wordNetEntry!.examples.take(3).map((example) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          example,
                          style: AppTheme.body1,
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ],
            
            // 同義語
            if (_wordNetEntry!.synonyms.isNotEmpty) ...[
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '類義語',
                    style: AppTheme.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _wordNetEntry!.synonyms
                        .take(6)
                        .map((synonym) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundSecondary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              child: Text(
                                synonym,
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ],
            
            // 下部の余白
            const SizedBox(height: 20),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

