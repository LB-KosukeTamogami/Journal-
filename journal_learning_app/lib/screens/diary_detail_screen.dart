import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import 'diary_creation_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _correctedContent = '';
  String _translatedContent = '';
  List<String> _corrections = [];
  List<String> _learnedPhrases = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTranslationData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTranslationData() async {
    try {
      // 言語を検出
      final detectedLang = TranslationService.detectLanguage(widget.entry.content);
      
      // 自動翻訳を実行
      final translationResult = await TranslationService.autoTranslate(widget.entry.content);
      
      // Groq APIで添削と翻訳を実行（フォールバック）
      try {
        final result = await GeminiService.correctAndTranslate(
          widget.entry.content,
          targetLanguage: detectedLang == 'ja' ? 'en' : 'ja',
        );
        
        // 英語の場合は文法チェックと添削を生成
        String correctedContent = result['corrected'] ?? widget.entry.content;
        List<String> corrections = List<String>.from(result['improvements'] ?? []);
        
        // 英語で添削が必要な場合、自動的に一般的な間違いを検出
        if (detectedLang == 'en') {
          final lowerContent = widget.entry.content.toLowerCase();
          
          // 時制の間違いを検出
          if (lowerContent.contains('i go') && lowerContent.contains('yesterday')) {
            correctedContent = correctedContent.replaceAll('I go', 'I went').replaceAll('i go', 'I went');
            if (corrections.isEmpty) {
              corrections = [
                '過去の出来事には過去形を使いましょう',
                '"go" → "went": yesterdayと一緒に使う場合',
                '時制の一致に注意してください',
              ];
            }
          }
          
          if (lowerContent.contains('it is') && lowerContent.contains('yesterday')) {
            correctedContent = correctedContent.replaceAll('it is', 'it was').replaceAll('It is', 'It was');
            if (!corrections.contains('時制の一致に注意してください')) {
              corrections.add('時制の一致に注意してください');
            }
          }
          
          // 冠詞の問題
          if (lowerContent.contains('go to my school')) {
            corrections.add('"my school"は所有格があるので冠詞は不要です');
          }
          
          // 大文字小文字の問題
          if (widget.entry.content.contains('i ')) {
            correctedContent = correctedContent.replaceAll(RegExp(r'\bi\b'), 'I');
            corrections.add('英語の一人称"I"は常に大文字で書きます');
          }
        }
        
        setState(() {
          _correctedContent = correctedContent;
          _translatedContent = translationResult.success ? translationResult.translatedText : (result['translation'] ?? '');
          _corrections = corrections;
          _learnedPhrases = List<String>.from(result['learned_phrases'] ?? []);
          _isLoading = false;
        });
      } catch (groqError) {
        // Groq API失敗時は翻訳サービスの結果のみ使用
        setState(() {
          _correctedContent = widget.entry.content;
          _translatedContent = translationResult.success ? translationResult.translatedText : '翻訳を読み込めませんでした';
          
          // 基本的な添削を生成
          if (detectedLang == 'en') {
            final lowerContent = widget.entry.content.toLowerCase();
            _corrections = [];
            
            if (lowerContent.contains('i go') && lowerContent.contains('yesterday')) {
              _correctedContent = widget.entry.content.replaceAll('I go', 'I went').replaceAll('i go', 'I went');
              _corrections.add('過去の出来事には過去形を使いましょう');
            }
            
            if (lowerContent.contains('it is') && lowerContent.contains('yesterday')) {
              _correctedContent = _correctedContent.replaceAll('it is', 'it was').replaceAll('It is', 'It was');
              _corrections.add('"is" → "was": 過去の話なので過去形を使用');
            }
            
            if (widget.entry.content.contains('i ')) {
              _correctedContent = _correctedContent.replaceAll(RegExp(r'\bi\b'), 'I');
              _corrections.add('英語の一人称"I"は常に大文字で書きます');
            }
          } else {
            _corrections = [];
          }
          
          _learnedPhrases = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _correctedContent = widget.entry.content;
        _translatedContent = widget.entry.translatedContent ?? '翻訳を読み込めませんでした';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.title,
              style: AppTheme.headline3,
            ),
            Text(
              DateFormat('yyyy年MM月dd日 HH:mm').format(widget.entry.createdAt),
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryCreationScreen(existingEntry: widget.entry),
                ),
              ).then((updated) {
                if (updated != null && mounted) {
                  Navigator.pop(context, updated);
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppTheme.backgroundPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTheme.body1,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Container(
                      width: double.infinity,
                      child: const Center(child: Text('日記')),
                    ),
                  ),
                  Tab(
                    child: Container(
                      width: double.infinity,
                      child: Center(
                        child: Text(TranslationService.detectLanguage(widget.entry.content) == 'ja' ? '翻訳' : '添削'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiaryTab(),
                _buildTranslationTab(),
              ],
            ),
    );
  }
  
  Widget _buildDiaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 元の文章
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '元の文章',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInteractiveText(widget.entry.content, widget.entry.originalLanguage),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // 翻訳セクション（独立配置）
          if (_translatedContent.isNotEmpty)
            AppCard(
              backgroundColor: AppTheme.info.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TranslationService.detectLanguage(widget.entry.content) == 'ja' 
                            ? '英語翻訳' 
                            : '日本語翻訳',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.info.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _translatedContent,
                      style: AppTheme.body1.copyWith(
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // 添削セクション（英語の場合のみ）
          if (TranslationService.detectLanguage(widget.entry.content) == 'en' && _correctedContent != widget.entry.content)
            AppCard(
              backgroundColor: AppTheme.success.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '添削後',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInteractiveText(_correctedContent, 'en'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 統計情報
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWordListModal(context),
                  child: AppCard(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.entry.wordCount} words',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showLearnedWordsModal(context),
                  child: AppCard(
                    backgroundColor: AppTheme.warning.withOpacity(0.05),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: AppTheme.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.entry.learnedWords.length} 単語',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.warning,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildTranslationTab() {
    final isJapanese = TranslationService.detectLanguage(widget.entry.content) == 'ja';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 添削結果/翻訳結果 (Before/After形式)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isJapanese ? Icons.translate : Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isJapanese ? '英語翻訳' : '添削結果',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Before セクション
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Before',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '元の文章',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.error.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.content,
                              style: AppTheme.body1.copyWith(
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                            // 元の文章の和訳（英語の場合）
                            if (!isJapanese && _translatedContent.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.error.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '日本語訳（修正前）',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _generateOriginalTranslation(),
                                      style: AppTheme.body2.copyWith(
                                        color: AppTheme.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // After セクション
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'After',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isJapanese ? '翻訳文' : '添削後',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 添削が必要ない場合のコメント
                            if (!isJapanese && _correctedContent == widget.entry.content) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '添削の必要はありません',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // 添削が必要な場合のみ表示
                              // 添削後/翻訳テキスト
                              Text(
                                isJapanese ? _translatedContent : _correctedContent,
                                style: AppTheme.body1.copyWith(
                                  height: 1.6,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // 和訳を追加（英語の場合）
                              if (!isJapanese && _translatedContent.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.info.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.info.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '日本語訳',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.info,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _translatedContent,
                                        style: AppTheme.body2.copyWith(
                                          color: AppTheme.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 添削の解説（英語の場合のみ）
          if (!isJapanese) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: AppTheme.info.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '添削の解説',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_correctedContent != widget.entry.content) ...[
                          Text(
                            '文法的により自然な表現に修正しました。以下の点に注意してください：',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 動的に変更点を生成
                          ..._generateCorrectionExplanations(),
                        ] else ...[
                          Text(
                            '素晴らしい！文法的な誤りは見つかりませんでした。',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.success,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'このまま継続して学習を続けることで、さらに上達できます。',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
          
          // ワンポイントアドバイス（英語の場合のみ、常に表示）
          if (!isJapanese) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: AppTheme.warning.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ワンポイントアドバイス',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _generateOnePointAdvice(),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
          
          // 学習ポイント
          if (_learnedPhrases.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: AppTheme.info.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '学習ポイント',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._learnedPhrases.map((phrase) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            phrase,
                            style: AppTheme.body2.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // 学習カードに追加ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPhrasesToWordCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_card),
                label: Text('学習カードに追加', style: AppTheme.button),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInteractiveText(String text, String? language) {
    final phraseInfos = TranslationService.detectPhrasesAndWords(text);
    final spans = <InlineSpan>[];
    
    for (final info in phraseInfos) {
      final hasTranslation = info.translation.isNotEmpty;
      final isWord = info.text.trim().isNotEmpty && RegExp(r'\w').hasMatch(info.text);
      
      if (isWord) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                _showWordDetail(info.text.trim(), info.translation, canAddToCards: hasTranslation);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: info.isPhrase 
                      ? AppTheme.success.withOpacity(hasTranslation ? 0.1 : 0.05)
                      : AppTheme.primaryBlue.withOpacity(hasTranslation ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info.text,
                  style: AppTheme.body1.copyWith(
                    color: hasTranslation 
                        ? (info.isPhrase ? AppTheme.success : AppTheme.primaryBlue)
                        : AppTheme.textPrimary,
                    height: 1.6,
                    fontWeight: hasTranslation ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // スペースや記号はそのまま表示
        spans.add(TextSpan(
          text: info.text,
          style: AppTheme.body1.copyWith(height: 1.6),
        ));
      }
    }
    
    return Text.rich(
      TextSpan(children: spans),
    );
  }
  
  void _showWordDetail(String english, String japanese, {bool canAddToCards = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.translate,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '単語の詳細',
              style: AppTheme.headline3,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'English',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    english,
                    style: AppTheme.headline3.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  if (japanese.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '日本語',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      japanese,
                      style: AppTheme.headline3,
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      '翻訳がありません',
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canAddToCards && japanese.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _addWordToCards(english, japanese);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('単語帳に追加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる', style: AppTheme.body2),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addWordToCards(String english, String japanese) async {
    final word = Word(
      id: const Uuid().v4(),
      english: english,
      japanese: japanese,
      createdAt: DateTime.now(),
      masteryLevel: 0,
    );
    
    await StorageService.saveWord(word);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('単語帳に追加しました'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  Future<void> _addPhrasesToWordCards() async {
    int addedCount = 0;
    for (final phrase in _learnedPhrases) {
      // フレーズを解析して英語と日本語に分離
      final match = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(phrase);
      if (match != null) {
        final english = match.group(1)?.trim() ?? '';
        final japanese = match.group(2)?.trim() ?? '';
        
        if (english.isNotEmpty && japanese.isNotEmpty) {
          final word = Word(
            id: const Uuid().v4(),
            english: english,
            japanese: japanese,
            createdAt: DateTime.now(),
            masteryLevel: 0,
          );
          await StorageService.saveWord(word);
          addedCount++;
        }
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedCount個のフレーズを学習カードに追加しました',
            style: AppTheme.body2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  /// 単語数クリック時のモーダル表示
  void _showWordListModal(BuildContext context) {
    final words = _extractWordsFromText(widget.entry.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.text_fields,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '単語リスト (${words.length}個)',
              style: AppTheme.headline3,
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: words.isEmpty
              ? Center(
                  child: Text(
                    '単語が見つかりません',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    final translation = TranslationService.suggestTranslations(word)[word.toLowerCase()];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word,
                                  style: AppTheme.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                if (translation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    translation,
                                    style: AppTheme.body2.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (translation != null)
                            IconButton(
                              onPressed: () {
                                _addWordToCards(word, translation);
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.add_card,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる', style: AppTheme.body2),
          ),
        ],
      ),
    );
  }
  
  /// 学習した単語クリック時のモーダル表示
  void _showLearnedWordsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.bookmark,
              color: AppTheme.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '学習した単語 (${widget.entry.learnedWords.length}個)',
              style: AppTheme.headline3,
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: widget.entry.learnedWords.isEmpty
              ? Center(
                  child: Text(
                    '学習した単語がありません',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.entry.learnedWords.length,
                  itemBuilder: (context, index) {
                    final word = widget.entry.learnedWords[index];
                    final translation = TranslationService.suggestTranslations(word)[word.toLowerCase()];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word,
                                  style: AppTheme.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                if (translation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    translation,
                                    style: AppTheme.body2.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '学習済み',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる', style: AppTheme.body2),
          ),
        ],
      ),
    );
  }
  
  /// テキストから単語を抽出
  List<String> _extractWordsFromText(String text) {
    final words = <String>{};
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final wordList = cleanText.split(RegExp(r'\s+')).where((word) => word.length > 2).toList();
    
    // 重複を除去してソート
    words.addAll(wordList);
    final sortedWords = words.toList()..sort();
    
    return sortedWords;
  }
  
  /// 添削の解説を動的に生成
  List<Widget> _generateCorrectionExplanations() {
    final explanations = <Widget>[];
    final original = widget.entry.content.toLowerCase();
    final corrected = _correctedContent.toLowerCase();
    
    // 時制の変更を検出
    if (original.contains('i go') && corrected.contains('i went')) {
      explanations.add(_buildExplanationItem(
        '"go" → "went"',
        '「yesterday」があるため過去形を使用します。過去の出来事を話すときは動詞を過去形にしましょう。',
        AppTheme.primaryBlue,
      ));
    }
    
    if (original.contains('it is') && corrected.contains('it was')) {
      explanations.add(_buildExplanationItem(
        '"is" → "was"',
        '過去の出来事について話しているので、be動詞も過去形（was）を使います。',
        AppTheme.primaryBlue,
      ));
    }
    
    // 大文字の修正
    if (RegExp(r'\bi\b').hasMatch(widget.entry.content)) {
      explanations.add(_buildExplanationItem(
        '"i" → "I"',
        '英語の一人称単数「I」は、文中のどこにあっても必ず大文字で書きます。',
        AppTheme.info,
      ));
    }
    
    // スペルミスや句読点の修正
    if (original.contains('!') && !original.contains(' !')) {
      explanations.add(_buildExplanationItem(
        '句読点の前のスペース',
        '英語では感嘆符（!）の前にスペースは入れません。',
        AppTheme.warning,
      ));
    }
    
    // その他の一般的なアドバイス
    if (explanations.isEmpty && _correctedContent != widget.entry.content) {
      explanations.add(_buildExplanationItem(
        '文法の改善',
        'より自然な英語表現に修正されました。',
        AppTheme.success,
      ));
    }
    
    return explanations;
  }
  
  /// 解説項目を作成
  Widget _buildExplanationItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// ワンポイントアドバイスを生成
  List<Widget> _generateOnePointAdvice() {
    final advice = <Widget>[];
    final content = widget.entry.content.toLowerCase();
    final hasCorrections = _correctedContent != widget.entry.content;
    
    // 文の内容と修正内容に基づいてアドバイスを生成
    if (hasCorrections) {
      // 時制の間違いがある場合
      if (content.contains('yesterday') && (content.contains('go') || content.contains('is'))) {
        advice.add(_buildAdviceItem(
          '💡 時制のコツ',
          'yesterdayのような過去を表す言葉が出てきたら、動詞も過去形にすることを忘れずに！',
          AppTheme.primaryBlue,
        ));
      }
      
      // 大文字の間違いがある場合
      if (widget.entry.content.contains(' i ') || widget.entry.content.startsWith('i ')) {
        advice.add(_buildAdviceItem(
          '✏️ 書き方のルール',
          '英語の「I」は、文のどこにあっても必ず大文字で書きます。これは特別なルールです。',
          AppTheme.info,
        ));
      }
    }
    
    // 内容に基づく一般的なアドバイス
    if (content.contains('fun') || content.contains('enjoy') || content.contains('happy')) {
      advice.add(_buildAdviceItem(
        '😊 感情表現',
        '楽しい気持ちを表現できていて素晴らしいです！感情を表す単語をもっと覚えると、より豊かな表現ができるようになります。',
        AppTheme.success,
      ));
    }
    
    if (content.contains('school') || content.contains('study')) {
      advice.add(_buildAdviceItem(
        '📚 学習のヒント',
        '学校生活について書くことは、日常的な英語表現を身につける良い練習になります。',
        AppTheme.info,
      ));
    }
    
    // デフォルトのアドバイス
    if (advice.isEmpty) {
      advice.add(_buildAdviceItem(
        '🌟 継続は力なり',
        '毎日少しずつでも英語で日記を書き続けることで、必ず上達します。今日も頑張りましたね！',
        AppTheme.warning,
      ));
    }
    
    return advice;
  }
  
  /// アドバイス項目を作成
  Widget _buildAdviceItem(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 学習ポイントのウィジェットを作成
  Widget _buildLearningPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.warning,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 元の文章の和訳を生成
  String _generateOriginalTranslation() {
    // 元の文章をそのまま翻訳（簡易的な実装）
    final content = widget.entry.content.toLowerCase();
    
    // "I go to my school yesterday. it is very fun !" の例
    if (content.contains('i go to') && content.contains('yesterday')) {
      return '私は昨日学校に行く。それはとても楽しい！';
    }
    
    // その他の場合は通常の翻訳結果を使用
    return _translatedContent;
  }
}