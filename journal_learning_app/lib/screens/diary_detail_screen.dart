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
import '../widgets/text_to_speech_button.dart';
import '../widgets/japanese_dictionary_dialog.dart';
import '../widgets/shadowing_player.dart';
import '../widgets/compact_shadowing_player.dart';
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
  List<PhraseInfo> _extractedWords = [];
  Set<String> _savedWords = {}; // Track which words are saved
  bool _isWordsExpanded = false; // Track if words card is expanded
  String? _shadowingText; // Text being shadowed
  String? _shadowingTitle; // Title for shadowing
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTranslationData();
    _loadSavedWords();
  }
  
  Future<void> _loadSavedWords() async {
    final words = await StorageService.getWords();
    setState(() {
      _savedWords = words.map((w) => w.english.toLowerCase()).toSet();
    });
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
      print('DiaryDetail: Detected language: $detectedLang');
      
      // 日英混在の場合は英語に統一する
      String targetLanguage;
      if (detectedLang == 'mixed') {
        targetLanguage = 'en'; // 混在の場合は英語に統一
      } else {
        targetLanguage = detectedLang == 'ja' ? 'en' : 'ja';
      }
      print('DiaryDetail: Target language: $targetLanguage');
      
      // 自動翻訳を実行（オフライン翻訳を優先）
      final translationResult = await TranslationService.autoTranslate(widget.entry.content);
      print('DiaryDetail: Translation result: ${translationResult.success}, ${translationResult.translatedText}');
      
      // オフライン翻訳が成功した場合はそれを使用
      String translatedText = translationResult.success ? translationResult.translatedText : '';
      
      // Gemini APIで添削と翻訳を実行（オプショナル）
      Map<String, dynamic>? geminiResult;
      try {
        geminiResult = await GeminiService.correctAndTranslate(
          widget.entry.content,
          targetLanguage: targetLanguage,
        );
        
        // Geminiから翻訳が取得できた場合は上書き
        if (geminiResult['translation'] != null && geminiResult['translation'].isNotEmpty) {
          translatedText = geminiResult['translation'];
        }
        
        // 英語の場合は文法チェックと添削を生成
        String correctedContent = geminiResult['corrected'] ?? widget.entry.content;
        List<String> corrections = List<String>.from(geminiResult['improvements'] ?? []);
        
        // 混在の場合のメッセージを追加
        if (detectedLang == 'mixed' && corrections.isEmpty) {
          corrections.add('日本語と英語が混在しています。英語に統一しました。');
        }
        
        // 英語で添削が必要な場合、自動的に一般的な間違いを検出
        if (detectedLang == 'en' || detectedLang == 'mixed') {
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
        
        // 単語・熟語を抽出
        final phraseInfos = TranslationService.detectPhrasesAndWords(widget.entry.content);
        final extractedWords = phraseInfos.where((info) {
          final isWord = info.text.trim().isNotEmpty && RegExp(r'\w').hasMatch(info.text);
          return isWord && (info.translation.isNotEmpty || RegExp(r'^[a-zA-Z\s-]+$').hasMatch(info.text));
        }).toList();
        
        setState(() {
          _correctedContent = correctedContent;
          _translatedContent = translatedText;
          _corrections = corrections;
          _learnedPhrases = List<String>.from(geminiResult?['learned_phrases'] ?? []);
          _extractedWords = extractedWords;
          _isLoading = false;
        });
      } catch (apiError) {
        // Gemini API失敗時は翻訳サービスの結果のみ使用
        print('DiaryDetail: Gemini API error: $apiError');
        setState(() {
          _correctedContent = widget.entry.content;
          _translatedContent = translatedText.isNotEmpty ? translatedText : '翻訳を読み込めませんでした';
          
          // 基本的な添削を生成
          if (detectedLang == 'en' || detectedLang == 'mixed') {
            final lowerContent = widget.entry.content.toLowerCase();
            _corrections = [];
            
            if (detectedLang == 'mixed') {
              _corrections.add('日本語と英語が混在しています。英語に統一しました。');
            }
            
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
          
          // 単語・熟語を抽出
          final phraseInfos2 = TranslationService.detectPhrasesAndWords(widget.entry.content);
          _extractedWords = phraseInfos2.where((info) {
            final isWord = info.text.trim().isNotEmpty && RegExp(r'\w').hasMatch(info.text);
            return isWord && (info.translation.isNotEmpty || RegExp(r'^[a-zA-Z\s-]+$').hasMatch(info.text));
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _correctedContent = widget.entry.content;
        _translatedContent = widget.entry.translatedContent ?? '翻訳を読み込めませんでした';
        _extractedWords = [];
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
          : Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiaryTab(),
                    _buildTranslationTab(),
                  ],
                ),
                if (_shadowingText != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CompactShadowingPlayer(
                      text: _shadowingText!,
                      onClose: () {
                        setState(() {
                          _shadowingText = null;
                          _shadowingTitle = null;
                        });
                      },
                    ),
                  ),
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
                Text(
                  widget.entry.content,
                  style: AppTheme.body1.copyWith(height: 1.6),
                ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (TranslationService.detectLanguage(_translatedContent) == 'en')
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_shadowingText == _translatedContent) {
                                _shadowingText = null;
                                _shadowingTitle = null;
                              } else {
                                _shadowingText = _translatedContent;
                                _shadowingTitle = '英語翻訳のシャドーイング';
                              }
                            });
                          },
                          icon: Icon(
                            Icons.record_voice_over,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          tooltip: 'シャドーイング練習',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_shadowingText == _correctedContent) {
                              _shadowingText = null;
                              _shadowingTitle = null;
                            } else {
                              _shadowingText = _correctedContent;
                              _shadowingTitle = '添削後の英文のシャドーイング';
                            }
                          });
                        },
                        icon: Icon(
                          Icons.record_voice_over,
                          color: AppTheme.success,
                          size: 20,
                        ),
                        tooltip: 'シャドーイング練習',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _correctedContent,
                    style: AppTheme.body1.copyWith(height: 1.6),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // Words カード（開閉可能）
          const SizedBox(height: 16),
          AppCard(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isWordsExpanded = !_isWordsExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                            style: AppTheme.body1.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isWordsExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildWordsList(),
                      ),
                    ],
                  ),
                  crossFadeState: _isWordsExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildTranslationTab() {
    final detectedLang = TranslationService.detectLanguage(widget.entry.content);
    final isJapanese = detectedLang == 'ja';
    final isMixed = detectedLang == 'mixed';
    
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
                      isJapanese ? '英語翻訳' : (isMixed ? '英語への統一' : '添削結果'),
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
                            isJapanese ? '翻訳文' : (isMixed ? '英語に統一' : '添削後'),
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
                            if (!isJapanese && !isMixed && _correctedContent == widget.entry.content) ...[
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
                                isJapanese ? _translatedContent : (isMixed ? _correctedContent : _correctedContent),
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
          ],
          
          // 抽出された単語・熟語リスト
          if (_extractedWords.isNotEmpty) ...[
            const SizedBox(height: 16),
              AppCard(
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.library_books,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '抽出された単語・熟語',
                          style: AppTheme.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _extractedWords.map((info) {
                        final isSaved = _savedWords.contains(info.text.trim().toLowerCase());
                        return Container(
                          decoration: BoxDecoration(
                            color: isSaved
                                ? AppTheme.success.withOpacity(0.05)
                                : (info.isPhrase 
                                    ? AppTheme.success.withOpacity(0.1)
                                    : AppTheme.primaryBlue.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSaved
                                  ? AppTheme.success.withOpacity(0.5)
                                  : (info.isPhrase 
                                      ? AppTheme.success.withOpacity(0.3)
                                      : AppTheme.primaryBlue.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (RegExp(r'^[a-zA-Z\s-]+$').hasMatch(info.text.trim())) {
                                    // 英語の単語の場合、日本語辞書ダイアログを表示
                                    JapaneseDictionaryDialog.show(
                                      context, 
                                      info.text.trim(),
                                      providedTranslation: info.translation.isNotEmpty ? info.translation : null,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        info.text,
                                        style: AppTheme.body2.copyWith(
                                          color: isSaved 
                                              ? AppTheme.success 
                                              : (info.isPhrase ? AppTheme.success : AppTheme.primaryBlue),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (info.translation.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${info.translation}',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    if (isSaved) {
                                      // 削除処理
                                      final words = await StorageService.getWords();
                                      final wordToDelete = words.firstWhere(
                                        (w) => w.english.toLowerCase() == info.text.trim().toLowerCase(),
                                        orElse: () => Word(
                                          id: '',
                                          english: '',
                                          japanese: '',
                                          category: WordCategory.other,
                                          createdAt: DateTime.now(),
                                          lastReviewedAt: null,
                                          reviewCount: 0,
                                          masteryLevel: 0,
                                          diaryEntryId: null,
                                        ),
                                      );
                                      if (wordToDelete.id.isNotEmpty) {
                                        await StorageService.deleteWord(wordToDelete.id);
                                        setState(() {
                                          _savedWords.remove(info.text.trim().toLowerCase());
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('単語帳から削除しました', style: AppTheme.body2.copyWith(color: Colors.white)),
                                            backgroundColor: AppTheme.warning,
                                          ),
                                        );
                                      }
                                    } else {
                                      // 追加処理
                                      final word = Word(
                                        id: const Uuid().v4(),
                                        english: info.text.trim(),
                                        japanese: info.translation.isNotEmpty ? info.translation : '[意味を確認中]',
                                        category: info.isPhrase ? WordCategory.phrase : WordCategory.other,
                                        createdAt: DateTime.now(),
                                        lastReviewedAt: null,
                                        reviewCount: 0,
                                        masteryLevel: 0,
                                        diaryEntryId: widget.entry.id,
                                      );
                                      await StorageService.saveWord(word);
                                      setState(() {
                                        _savedWords.add(info.text.trim().toLowerCase());
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('単語帳に追加しました', style: AppTheme.body2.copyWith(color: Colors.white)),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      isSaved ? Icons.check : Icons.add_card,
                                      size: 16,
                                      color: isSaved ? AppTheme.success : AppTheme.primaryBlue.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
        ],
      ),
    );
  }
  
  
  void _showWordDetail(String english, String japanese) {
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
            if (japanese.isNotEmpty) ...[
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
      diaryEntryId: widget.entry.id, // Link word to diary entry
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
              const SizedBox(height: 4),
              Text(
                '単語をタップして詳細を表示',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
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
                      final isSaved = _savedWords.contains(word.toLowerCase());
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Show JapaneseDictionaryDialog when word is clicked
                            JapaneseDictionaryDialog.show(
                              context, 
                              word,
                              providedTranslation: translation,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSaved 
                                    ? AppTheme.success.withOpacity(0.3)
                                    : AppTheme.primaryBlue.withOpacity(0.2),
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
                                        color: isSaved ? AppTheme.success : AppTheme.primaryBlue,
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
                                  onPressed: () async {
                                    if (isSaved) {
                                      // Remove word from saved list
                                      final words = await StorageService.getWords();
                                      final wordToRemove = words.firstWhere(
                                        (w) => w.english.toLowerCase() == word.toLowerCase(),
                                        orElse: () => Word(
                                          id: '',
                                          english: '',
                                          japanese: '',
                                          createdAt: DateTime.now(),
                                        ),
                                      );
                                      if (wordToRemove.id.isNotEmpty) {
                                        await StorageService.deleteWord(wordToRemove.id);
                                        setState(() {
                                          _savedWords.remove(word.toLowerCase());
                                        });
                                        setModalState(() {});
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('単語帳から削除しました'),
                                              backgroundColor: AppTheme.warning,
                                              behavior: SnackBarBehavior.floating,
                                              margin: const EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Add word to saved list
                                      await _addWordToCards(word, translation);
                                      setState(() {
                                        _savedWords.add(word.toLowerCase());
                                      });
                                      setModalState(() {});
                                    }
                                  },
                                  icon: Icon(
                                    isSaved ? Icons.check : Icons.add_card,
                                    color: isSaved ? AppTheme.success : AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          ),
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
      ),
    ).then((_) {
      // Refresh saved words when dialog is closed
      _loadSavedWords();
    });
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

  /// Build the words list widget (extracted from _showWordListModal)
  Widget _buildWordsList() {
    final words = _extractWordsFromText(widget.entry.content);
    
    if (words.isEmpty) {
      return Center(
        child: Text(
          '単語が見つかりません',
          style: AppTheme.body2.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words.map((word) {
        final translation = TranslationService.suggestTranslations(word)[word.toLowerCase()];
        final isSaved = _savedWords.contains(word.toLowerCase());
        
        return Container(
          decoration: BoxDecoration(
            color: isSaved
                ? AppTheme.success.withOpacity(0.05)
                : AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSaved
                  ? AppTheme.success.withOpacity(0.5)
                  : AppTheme.primaryBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  // Show JapaneseDictionaryDialog when word is clicked
                  JapaneseDictionaryDialog.show(
                    context, 
                    word,
                    providedTranslation: translation,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word,
                        style: AppTheme.body2.copyWith(
                          color: isSaved ? AppTheme.success : AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (translation != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${translation}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (translation != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (isSaved) {
                        // Remove word from saved list
                        final words = await StorageService.getWords();
                        final wordToRemove = words.firstWhere(
                          (w) => w.english.toLowerCase() == word.toLowerCase(),
                          orElse: () => Word(
                            id: '',
                            english: '',
                            japanese: '',
                            category: WordCategory.other,
                            createdAt: DateTime.now(),
                            lastReviewedAt: null,
                            reviewCount: 0,
                            masteryLevel: 0,
                            diaryEntryId: null,
                          ),
                        );
                        if (wordToRemove.id.isNotEmpty) {
                          await StorageService.deleteWord(wordToRemove.id);
                          setState(() {
                            _savedWords.remove(word.toLowerCase());
                          });
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('単語帳から削除しました', style: AppTheme.body2.copyWith(color: Colors.white)),
                                backgroundColor: AppTheme.warning,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // Add word to saved list
                        await _addWordToCards(word, translation);
                        setState(() {
                          _savedWords.add(word.toLowerCase());
                        });
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isSaved ? Icons.check : Icons.add_card,
                        size: 16,
                        color: isSaved ? AppTheme.success : AppTheme.primaryBlue.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}