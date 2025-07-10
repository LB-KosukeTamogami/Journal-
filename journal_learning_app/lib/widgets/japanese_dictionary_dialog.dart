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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: 350,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '日本語辞書',
                      style: AppTheme.headline3.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // コンテンツ
            Flexible(
              child: _isLoading
                  ? Container(
                      padding: const EdgeInsets.all(40),
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
                  : _wordNetEntry == null
                      ? Container(
                          padding: const EdgeInsets.all(40),
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
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 単語
                              Text(
                                _wordNetEntry!.word,
                                style: AppTheme.headline1.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                              
                              const SizedBox(height: 16),
                              
                              // 品詞
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
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
                              ).animate().fadeIn(delay: 100.ms, duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                              
                              const SizedBox(height: 24),
                              
                              // 日本語の意味
                              if (_wordNetEntry!.definitions.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.translate,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '日本語の意味',
                                            style: AppTheme.body2.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _wordNetEntry!.definitions.map((def) => 
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: AppTheme.body1.copyWith(
                                                    color: AppTheme.primaryColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    def,
                                                    style: AppTheme.body1.copyWith(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ).toList(),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                              ],
                              
                              // 例文
                              if (_wordNetEntry!.examples.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.success.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote,
                                            size: 20,
                                            color: AppTheme.success,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '例文',
                                            style: AppTheme.body2.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ..._wordNetEntry!.examples.map((example) =>
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            example,
                                            style: AppTheme.body2.copyWith(
                                              fontStyle: FontStyle.italic,
                                              height: 1.5,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ).toList(),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                              ],
                              
                              // 同義語
                              if (_wordNetEntry!.synonyms.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sync_alt,
                                          size: 20,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '同義語',
                                          style: AppTheme.body2.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
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
                                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}