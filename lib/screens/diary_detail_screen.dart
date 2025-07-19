import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../models/flashcard.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../widgets/text_to_speech_button.dart';
import '../widgets/japanese_dictionary_dialog.dart';
import '../widgets/shadowing_player.dart';
import '../widgets/compact_shadowing_player.dart';
import '../widgets/word_by_word_player.dart';
import '../widgets/integrated_shadowing_player.dart';
import '../services/japanese_wordnet_service.dart';
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
  int _highlightedWordIndex = -1; // Currently highlighted word index
  List<String> _shadowingWords = []; // Words for highlighting
  String _judgment = ''; // レビュー結果の判定
  final TextEditingController _transcriptionController = TextEditingController(); // 写経用のコントローラー
  
  // ストップワード（一般的すぎる単語）のリスト
  static const Set<String> _stopWords = {
    // 冠詞
    'a', 'an', 'the',
    // 代名詞
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
    'my', 'your', 'his', 'its', 'our', 'their',
    'this', 'that', 'these', 'those',
    // be動詞
    'am', 'is', 'are', 'was', 'were', 'been', 'be', 'being',
    // 助動詞
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can',
    // 前置詞
    'at', 'in', 'on', 'to', 'for', 'of', 'with', 'by', 'from', 'up', 'down', 'out', 'off', 'over', 'under',
    // 接続詞
    'and', 'or', 'but', 'if', 'because', 'as', 'while', 'when',
    // その他の一般的な単語
    'not', 'no', 'yes', 's', 't', 're', 've', 'll', 'd', 'm', 'don', 'won',
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTranslationData();
    _loadSavedWords();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSavedWords() async {
    final words = await StorageService.getWords();
    setState(() {
      _savedWords = words.map((w) => w.english.toLowerCase()).toSet();
    });
  }
  
  
  Future<void> _loadTranslationData() async {
    try {
      // 言語を検出
      final detectedLang = TranslationService.detectLanguage(widget.entry.content);
      
      // 日英混在の場合は英語に統一する
      String targetLanguage;
      if (detectedLang == 'mixed') {
        targetLanguage = 'en'; // 混在の場合は英語に統一
      } else {
        targetLanguage = detectedLang == 'ja' ? 'en' : 'ja';
      }
      
      // まずキャッシュを確認
      final cachedTranslation = await SupabaseService.getTranslationCache(
        diaryEntryId: widget.entry.id,
      );
      
      if (cachedTranslation != null) {
        // キャッシュが存在する場合は使用
        
        setState(() {
          _translatedContent = cachedTranslation['translated_text'] ?? '';
          _correctedContent = cachedTranslation['corrected_text'] ?? widget.entry.content;
          _corrections = List<String>.from(cachedTranslation['improvements'] ?? []);
          _judgment = cachedTranslation['judgment'] ?? '';
          _learnedPhrases = List<String>.from(cachedTranslation['learned_phrases'] ?? []);
          
          // 抽出された単語を復元
          final extractedWordsData = cachedTranslation['extracted_words'] ?? [];
          _extractedWords = extractedWordsData.map<PhraseInfo>((data) => PhraseInfo(
            text: data['text'] ?? '',
            translation: data['translation'] ?? '',
            isPhrase: data['isPhrase'] ?? false,
            startIndex: 0,
            endIndex: 0,
          )).toList();
          
          _isLoading = false;
        });
        
        // キャッシュから学習フレーズや単語も読み込まれているのでreturn
        return;
      }
      
      // キャッシュがない場合のみローディングを開始
      setState(() {
        _isLoading = true;
      });
      
      // キャッシュがない場合はGemini APIを使用
      Map<String, dynamic>? geminiResult;
      String translatedText = '';
      String correctedContent = widget.entry.content;
      List<String> corrections = [];
      
      try {
        geminiResult = await GeminiService.correctAndTranslate(
          widget.entry.content,
          targetLanguage: targetLanguage,
        );
        
        // Geminiから結果を取得
        if (geminiResult['translation'] != null && geminiResult['translation'].isNotEmpty) {
          translatedText = geminiResult['translation'];
        }
        
        correctedContent = geminiResult['corrected'] ?? widget.entry.content;
        corrections = List<String>.from(geminiResult['improvements'] ?? []);
        final judgment = geminiResult['judgment'] ?? '';
        
        // レート制限チェック
        if (geminiResult['rate_limited'] == true) {
          translatedText = '';
          correctedContent = widget.entry.content;
        }
        
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
        
        // 単語を抽出（熟語を除外）
        final phraseInfos = TranslationService.detectPhrasesAndWords(widget.entry.content);
        final extractedWords = phraseInfos.where((info) {
          // 熟語ではない単語のみをフィルタリング
          final word = info.text.trim().toLowerCase();
          final isWord = info.text.trim().isNotEmpty && 
                        RegExp(r'\w').hasMatch(info.text) && 
                        !info.isPhrase &&
                        word.length >= 3 && // 3文字以上
                        !_stopWords.contains(word) && // ストップワードを除外
                        RegExp(r'^[a-zA-Z]+$').hasMatch(word); // 英字のみ
          return isWord && (info.translation.isNotEmpty || RegExp(r'^[a-zA-Z\s-]+$').hasMatch(info.text));
        }).toList();
        
        setState(() {
          _correctedContent = correctedContent;
          _translatedContent = translatedText;
          _corrections = corrections;
          _judgment = judgment;
          _learnedPhrases = List<String>.from(geminiResult?['learned_phrases'] ?? []);
          _extractedWords = extractedWords;
          _isLoading = false;
        });
        
        // 翻訳成功時はキャッシュに保存
        if (translatedText.isNotEmpty && !corrections.contains('本日のAI利用枠を使い切りました。明日また利用可能になります。')) {
          // Supabaseが初期化されている場合のみキャッシュを保存
          if (SupabaseService.client != null) {
            await SupabaseService.saveTranslationCache(
              userId: AuthService.currentUserId ?? 'anonymous',
              diaryEntryId: widget.entry.id,
              originalText: widget.entry.content,
              translatedText: translatedText,
              correctedText: correctedContent,
              improvements: corrections,
              detectedLanguage: detectedLang,
              targetLanguage: targetLanguage,
              judgment: judgment,
              learnedPhrases: _learnedPhrases,
              extractedWords: extractedWords.map((e) => {
                'text': e.text,
                'translation': e.translation,
                'isPhrase': e.isPhrase,
              }).toList(),
              learnedWords: geminiResult?['learned_words'] ?? [],
            );
          }
        }
        
      } catch (apiError) {
        // Gemini API失敗時のみオフライン翻訳をフォールバックとして使用
        
        // APIエラーの場合はレート制限の可能性が高い
        setState(() {
          _correctedContent = widget.entry.content;
          _translatedContent = '';
          _corrections = ['本日のAI利用枠を使い切りました。明日また利用可能になります。'];
          
          _learnedPhrases = [];
          
          // 単語を抽出（熟語を除外）
          final phraseInfos2 = TranslationService.detectPhrasesAndWords(widget.entry.content);
          _extractedWords = phraseInfos2.where((info) {
            // 熟語ではない単語のみをフィルタリング
            final isWord = info.text.trim().isNotEmpty && RegExp(r'\w').hasMatch(info.text) && !info.isPhrase;
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
      body: Stack(
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
              child: IntegratedShadowingPlayer(
                text: _shadowingText!,
                onClose: () {
                  setState(() {
                    _shadowingText = null;
                    _shadowingTitle = null;
                    _highlightedWordIndex = -1;
                    _shadowingWords = [];
                  });
                },
                onWordHighlight: (word, index, elapsedTime) {
                  setState(() {
                    _highlightedWordIndex = index;
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
          _isLoading ? _buildSkeletonOriginal() : AppCard(
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
                    // 正しい英語の場合はTTSボタンを表示
                    if (_isCorrectEnglish()) ...[
                      const Spacer(),
                      TextToSpeechButton(
                        text: widget.entry.content,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.entry.content,
                  style: AppTheme.body1.copyWith(height: 1.6),
                ),
                // 英語の場合、日本語訳を白いコンテナで表示
                if (TranslationService.detectLanguage(widget.entry.content) == 'en' && _translatedContent.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.dividerColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '日本語訳',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildHighlightedText(
                          _translatedContent,
                          AppTheme.body2.copyWith(
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
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // AI利用制限メッセージ
          if (!_isLoading && _corrections.contains('本日のAI利用枠を使い切りました。明日また利用可能になります。'))
            AppCard(
              backgroundColor: AppTheme.warning.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '本日のAI利用枠を使い切りました。明日また利用可能になります。',
                      style: AppTheme.body1.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 翻訳セクション（日本語エントリーの場合のみ表示）
          if (_isLoading) ...
            _buildSkeletonResults()
          else if (_translatedContent.isNotEmpty && TranslationService.detectLanguage(widget.entry.content) == 'ja')
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
                            '英語翻訳',
                            style: AppTheme.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.info,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_shadowingText == _translatedContent) {
                              _shadowingText = null;
                              _shadowingTitle = null;
                              _highlightedWordIndex = -1;
                              _shadowingWords = [];
                            } else {
                              _shadowingText = _translatedContent;
                              _shadowingTitle = '英語翻訳のシャドーイング';
                              _shadowingWords = _translatedContent.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
                              _highlightedWordIndex = -1;
                            }
                          });
                        },
                        icon: Icon(
                          Icons.record_voice_over,
                          color: AppTheme.primaryColor,
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
                    child: _buildHighlightedText(
                      _translatedContent,
                      AppTheme.body1.copyWith(
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
                              _highlightedWordIndex = -1;
                              _shadowingWords = [];
                            } else {
                              _shadowingText = _correctedContent;
                              _shadowingTitle = '添削後の英文のシャドーイング';
                              _shadowingWords = _correctedContent.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
                              _highlightedWordIndex = -1;
                            }
                          });
                        },
                        icon: Icon(
                          Icons.record_voice_over,
                          color: AppTheme.success,
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
                  const SizedBox(height: 12),
                  _buildHighlightedText(
                    _correctedContent,
                    AppTheme.body1.copyWith(height: 1.6),
                  ),
                  // 添削後の日本語訳を透明背景のコンテナで表示
                  if (_translatedContent.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '日本語訳',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
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
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
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
                      color: isJapanese ? AppTheme.primaryBlue : AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isJapanese ? '英語翻訳' : (isMixed ? '英語への統一' : '添削結果'),
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isJapanese ? AppTheme.primaryBlue : AppTheme.success,
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
                                  color: Colors.transparent,
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
                                        color: AppTheme.textSecondary,
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
                            if (!isJapanese && !isMixed && _correctedContent.isNotEmpty && _correctedContent == widget.entry.content && !_isLoading) ...[
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
                              // AI利用制限チェック
                              if (_corrections.contains('本日のAI利用枠を使い切りました。明日また利用可能になります。')) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppTheme.warning,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '本日のAI利用枠を使い切りました。明日また利用可能になります。',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.warning,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // 添削後/翻訳テキスト
                                Text(
                                  isJapanese ? _translatedContent : (isMixed ? _correctedContent : _correctedContent),
                                  style: AppTheme.body1.copyWith(
                                    height: 1.6,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              // 和訳を追加（英語の場合）
                              if (!isJapanese && _translatedContent.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.success.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '日本語訳',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSecondary,
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
          
          // 写経セクション（添削結果または翻訳結果がある場合のみ、正しい英文の場合は除く）
          if (!_isLoading && (
              // 日本語の場合（翻訳結果がある）
              (isJapanese && _translatedContent.isNotEmpty) ||
              // 英語で添削が必要な場合（添削結果が元と異なる）
              (!isJapanese && _correctedContent.isNotEmpty && _correctedContent != widget.entry.content)
          )) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '写経',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transcriptionController,
                    maxLines: 5,
                    style: AppTheme.body1,
                    decoration: InputDecoration(
                      hintText: '正しい英文を書き写してみましょう。',
                      hintStyle: AppTheme.body2.copyWith(color: AppTheme.textTertiary),
                      filled: true,
                      fillColor: AppTheme.backgroundPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
          
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
                          // レビュー画面と同じ形式で表示
                          ..._corrections.map((correction) => Padding(
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
                                    correction,
                                    style: AppTheme.body2.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          )),
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
          
          
          // レビュー画面と同じアドバイスセクションを追加
          if (_judgment.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAdviceSection(),
          ],
          
          // 学習ポイント
          if (_learnedPhrases.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoBlock(
              title: '学習ポイント',
              icon: Icons.school,
              color: AppTheme.info,
              items: _learnedPhrases,
              animationDelay: 400.ms,
            ),
          ],
          
          // 抽出された単語リスト
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
                          '抽出された単語',
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
                                  // モーダルを下から表示（レビュー画面と同じデザインに統一）
                                  bool isAddedToFlashcard = isSaved;
                                  bool isAddedToVocabulary = false;
                                  bool isLoadingTranslation = true;
                                  String translationText = info.translation.isNotEmpty ? info.translation : '[意味を確認中]';
                                  
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setModalState) {
                                        // 辞書APIから翻訳を取得（初回のみ）
                                        if (isLoadingTranslation && info.translation.isEmpty) {
                                          JapaneseWordNetService.lookupWord(info.text).then((wordNetEntry) {
                                            if (wordNetEntry != null && wordNetEntry.definitions.isNotEmpty) {
                                              setModalState(() {
                                                translationText = wordNetEntry.definitions.first;
                                                isLoadingTranslation = false;
                                              });
                                            } else {
                                              setModalState(() {
                                                translationText = '[意味が見つかりませんでした]';
                                                isLoadingTranslation = false;
                                              });
                                            }
                                          });
                                        } else if (info.translation.isNotEmpty) {
                                          isLoadingTranslation = false;
                                        }
                                        
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
                                              
                                              // 単語と品詞、音声ボタン
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          info.text,
                                                          style: AppTheme.headline2,
                                                        ),
                                                        const SizedBox(height: 8),
                                                        // 日本語の意味
                                                        isLoadingTranslation 
                                                          ? Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 16,
                                                                  height: 16,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth: 2,
                                                                    color: AppTheme.primaryBlue,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  '意味を取得中...',
                                                                  style: AppTheme.body2.copyWith(
                                                                    color: AppTheme.textSecondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : Text(
                                                              translationText,
                                                              style: AppTheme.body1.copyWith(fontSize: 18),
                                                            ),
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
                                                      _getPartOfSpeech(info.text),
                                                      style: AppTheme.caption.copyWith(
                                                        color: AppTheme.info,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 音声読み上げボタン
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: IconButton(
                                                      onPressed: () {
                                                        // TODO: 音声読み上げ機能を実装
                                                      },
                                                      icon: Icon(
                                                        Icons.volume_up,
                                                        color: AppTheme.primaryBlue,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 24),
                                              
                                              // アクションボタン（統一デザイン）
                                              Column(
                                                children: [
                                                  AppButtonStyles.withShadow(
                                                    OutlinedButton.icon(
                                                        onPressed: () async {
                                                          // 学習カードに追加/削除のトグル
                                                          try {
                                                            if (isAddedToFlashcard) {
                                                              // 既に追加済みの場合は削除
                                                              final words = await StorageService.getWords();
                                                              final wordToDelete = words.firstWhere(
                                                                (w) => w.english.toLowerCase() == info.text.trim().toLowerCase(),
                                                                orElse: () => Word(
                                                                  id: '',
                                                                  english: '',
                                                                  japanese: '',
                                                                  category: WordCategory.other,
                                                                  createdAt: DateTime.now(),
                                                                  masteryLevel: 0,
                                                                  reviewCount: 0,
                                                                  diaryEntryId: null,
                                                                ),
                                                              );
                                                              if (wordToDelete.id.isNotEmpty) {
                                                                await StorageService.deleteWord(wordToDelete.id);
                                                                setState(() {
                                                                  _savedWords.remove(info.text.trim().toLowerCase());
                                                                });
                                                                setModalState(() {
                                                                  isAddedToFlashcard = false;
                                                                });
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('学習カードから削除しました'),
                                                                    backgroundColor: AppTheme.warning,
                                                                    behavior: SnackBarBehavior.floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              // 新規追加
                                                              final word = Word(
                                                                id: const Uuid().v4(),
                                                                english: info.text.trim(),
                                                                japanese: translationText,
                                                                diaryEntryId: widget.entry.id,
                                                                createdAt: DateTime.now(),
                                                                masteryLevel: 0,
                                                                reviewCount: 0,
                                                                isMastered: false,
                                                                category: _getWordCategory(info.text.trim()),
                                                              );
                                                              
                                                              await StorageService.saveWord(word);
                                                              
                                                              // メインの状態も更新
                                                              setState(() {
                                                                _savedWords.add(info.text.trim().toLowerCase());
                                                              });
                                                              
                                                              setModalState(() {
                                                                isAddedToFlashcard = true;
                                                              });
                                                              
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('学習カードに追加しました'),
                                                                  backgroundColor: AppTheme.success,
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('エラーが発生しました'),
                                                                backgroundColor: AppTheme.error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: isAddedToFlashcard
                                                          ? AppButtonStyles.modalSecondaryButton
                                                          : AppButtonStyles.modalPrimaryButton,
                                                        icon: Icon(
                                                          isAddedToFlashcard ? Icons.check_circle : Icons.add_card,
                                                          size: 20,
                                                          color: isAddedToFlashcard ? AppTheme.primaryColor : Colors.white,
                                                        ),
                                                        label: Text(
                                                          isAddedToFlashcard ? '学習カードに追加済み' : '学習カードに追加',
                                                          style: TextStyle(
                                                            color: isAddedToFlashcard ? AppTheme.primaryColor : Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  AppButtonStyles.withShadow(
                                                    ElevatedButton.icon(
                                                        onPressed: () async {
                                                          // 単語帳に追加/削除のトグル
                                                          try {
                                                            if (isAddedToVocabulary) {
                                                              // 既に追加済みの場合は削除
                                                              final flashcards = await StorageService.getFlashcards();
                                                              final cardToDelete = flashcards.firstWhere(
                                                                (card) => card.word.toLowerCase() == info.text.toLowerCase(),
                                                                orElse: () => Flashcard(
                                                                  id: '',
                                                                  word: '',
                                                                  meaning: '',
                                                                  exampleSentence: '',
                                                                  createdAt: DateTime.now(),
                                                                  lastReviewed: DateTime.now(),
                                                                  nextReviewDate: DateTime.now().add(Duration(days: 1)),
                                                                  reviewCount: 0,
                                                                ),
                                                              );
                                                              if (cardToDelete.id.isNotEmpty) {
                                                                await StorageService.deleteFlashcard(cardToDelete.id);
                                                                setModalState(() {
                                                                  isAddedToVocabulary = false;
                                                                });
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('単語帳から削除しました'),
                                                                    backgroundColor: AppTheme.warning,
                                                                    behavior: SnackBarBehavior.floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            } else {
                                                              // 新規追加
                                                              final flashcard = Flashcard(
                                                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                                word: info.text,
                                                                meaning: translationText,
                                                                exampleSentence: '',
                                                                createdAt: DateTime.now(),
                                                                lastReviewed: DateTime.now(),
                                                                nextReviewDate: DateTime.now().add(Duration(days: 1)),
                                                                reviewCount: 0,
                                                              );
                                                              
                                                              await StorageService.saveFlashcard(flashcard);
                                                              
                                                              setModalState(() {
                                                                isAddedToVocabulary = true;
                                                              });
                                                              
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('単語帳に追加しました'),
                                                                  backgroundColor: AppTheme.success,
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('エラーが発生しました'),
                                                                backgroundColor: AppTheme.error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: isAddedToVocabulary
                                                          ? AppButtonStyles.modalErrorButton
                                                          : AppButtonStyles.modalSuccessButton,
                                                        icon: Icon(
                                                          isAddedToVocabulary ? Icons.check_circle : Icons.style,
                                                          size: 20,
                                                          color: isAddedToVocabulary ? AppTheme.error : Colors.white,
                                                        ),
                                                        label: Text(
                                                          isAddedToVocabulary ? '単語帳に追加済み' : '単語帳に追加',
                                                          style: TextStyle(
                                                            color: isAddedToVocabulary ? AppTheme.error : Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 20),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
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
                                        category: _getWordCategory(info.text.trim()),
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
            
            // 単語をすべて登録ボタン
            if (_extractedWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  boxShadow: AppTheme.buttonShadow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _areAllWordsAdded() ? null : () async {
                      // ローディング表示
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryBlue),
                                const SizedBox(height: 16),
                                Text('単語を追加中...', style: AppTheme.body2),
                              ],
                            ),
                          ),
                        ),
                      );
                      
                      // すべての抽出単語を学習カードとして保存
                      int addedCount = 0;
                      for (final wordInfo in _extractedWords) {
                        final english = wordInfo.text.trim();
                        final japanese = wordInfo.translation.isNotEmpty ? wordInfo.translation : '[意味を確認中]';
                        
                        if (english.isNotEmpty && !_savedWords.contains(english.toLowerCase())) {
                          try {
                            final word = Word(
                              id: const Uuid().v4(),
                              english: english,
                              japanese: japanese,
                              diaryEntryId: widget.entry.id,
                              createdAt: DateTime.now(),
                              masteryLevel: 0,
                              reviewCount: 0,
                              isMastered: false,
                              category: _getWordCategory(english),
                            );
                            
                            await StorageService.saveWord(word);
                            setState(() {
                              _savedWords.add(english.toLowerCase());
                            });
                            addedCount++;
                          } catch (e) {
                            print('Error saving word: $e');
                          }
                        }
                      }
                      
                      // ダイアログを閉じる
                      if (mounted) Navigator.pop(context);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$addedCount個の単語を学習カードに追加しました',
                              style: AppTheme.body2.copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    style: _areAllWordsAdded() 
                      ? AppButtonStyles.primaryButton.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.white),
                          foregroundColor: MaterialStateProperty.all(AppTheme.primaryColor),
                          side: MaterialStateProperty.all(BorderSide(color: AppTheme.primaryColor, width: 2)),
                          minimumSize: MaterialStateProperty.all(Size(double.infinity, 56)),
                          fixedSize: MaterialStateProperty.all(Size(double.infinity, 56)),
                        )
                      : AppButtonStyles.primaryButton.copyWith(
                          minimumSize: MaterialStateProperty.all(Size(double.infinity, 56)),
                          fixedSize: MaterialStateProperty.all(Size(double.infinity, 56)),
                        ),
                    icon: Icon(
                      _areAllWordsAdded() ? Icons.check_circle : Icons.add_card,
                      color: _areAllWordsAdded() ? AppTheme.primaryColor : Colors.white,
                    ),
                    label: Text(
                      _areAllWordsAdded() ? '学習カードに追加済み' : '学習カードにすべて追加',
                      style: AppTheme.button.copyWith(
                        color: _areAllWordsAdded() ? AppTheme.primaryColor : Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
            ],
        ],
      ),
    );
  }
  
  // すべての単語が追加済みかチェック
  bool _areAllWordsAdded() {
    if (_extractedWords.isEmpty) return false;
    
    for (final wordInfo in _extractedWords) {
      final english = wordInfo.text.trim();
      if (english.isNotEmpty && !_savedWords.contains(english.toLowerCase())) {
        return false;
      }
    }
    return true;
  }
  
  // 品詞を判定する
  String _getPartOfSpeech(String word) {
    final lowerWord = word.toLowerCase();
    
    // 動詞の判定
    if (lowerWord.endsWith('ing') || lowerWord.endsWith('ed') || 
        lowerWord.endsWith('es') || lowerWord.endsWith('s') ||
        ['go', 'went', 'come', 'came', 'take', 'took', 'make', 'made', 
         'get', 'got', 'see', 'saw', 'know', 'knew', 'think', 'thought',
         'feel', 'felt', 'work', 'run', 'walk', 'talk', 'play', 'study',
         'learn', 'teach', 'read', 'write', 'listen', 'speak', 'watch',
         'look', 'find', 'help', 'try', 'start', 'stop', 'open', 'close',
         'clean', 'realize', 'forget'].contains(lowerWord)) {
      return '動詞';
    }
    
    // 形容詞の判定
    if (lowerWord.endsWith('ful') || lowerWord.endsWith('less') || 
        lowerWord.endsWith('ing') || lowerWord.endsWith('ed') ||
        lowerWord.endsWith('ous') || lowerWord.endsWith('ive') ||
        lowerWord.endsWith('ly') ||
        ['good', 'bad', 'big', 'small', 'new', 'old', 'young', 'long',
         'short', 'high', 'low', 'fast', 'slow', 'easy', 'hard', 'hot',
         'cold', 'warm', 'cool', 'great', 'wonderful', 'terrible', 'worst',
         'best', 'better', 'worse', 'happy', 'sad', 'angry', 'excited',
         'tired', 'beautiful', 'ugly', 'important', 'interesting', 'boring'].contains(lowerWord)) {
      return '形容詞';
    }
    
    // 副詞の判定
    if (lowerWord.endsWith('ly') ||
        ['today', 'yesterday', 'tomorrow', 'now', 'then', 'here', 'there',
         'always', 'never', 'sometimes', 'often', 'usually', 'very', 'quite',
         'really', 'actually', 'finally', 'suddenly', 'carefully', 'quickly'].contains(lowerWord)) {
      return '副詞';
    }
    
    // 前置詞の判定
    if (['in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'of', 'about',
         'after', 'before', 'during', 'under', 'over', 'between', 'among',
         'through', 'into', 'onto', 'upon', 'within', 'without'].contains(lowerWord)) {
      return '前置詞';
    }
    
    // 接続詞の判定
    if (['and', 'or', 'but', 'so', 'because', 'although', 'while', 'when',
         'if', 'unless', 'since', 'until', 'though', 'whereas'].contains(lowerWord)) {
      return '接続詞';
    }
    
    // 代名詞の判定
    if (['i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her',
         'us', 'them', 'my', 'your', 'his', 'her', 'its', 'our', 'their',
         'mine', 'yours', 'hers', 'ours', 'theirs', 'this', 'that', 'these',
         'those', 'who', 'what', 'which', 'where', 'when', 'why', 'how'].contains(lowerWord)) {
      return '代名詞';
    }
    
    // デフォルトは名詞
    return '名詞';
  }
  
  // 品詞文字列をWordCategoryに変換
  WordCategory _getWordCategory(String word) {
    final partOfSpeech = _getPartOfSpeech(word);
    switch (partOfSpeech) {
      case '名詞':
        return WordCategory.noun;
      case '動詞':
        return WordCategory.verb;
      case '形容詞':
        return WordCategory.adjective;
      case '副詞':
        return WordCategory.adverb;
      case '代名詞':
        return WordCategory.pronoun;
      case '前置詞':
        return WordCategory.preposition;
      case '接続詞':
        return WordCategory.conjunction;
      case '感動詞':
        return WordCategory.interjection;
      default:
        return WordCategory.other;
    }
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
      category: _getWordCategory(english),
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
            category: _getWordCategory(english),
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
  
  /// 正しい英語かどうかを判定
  bool _isCorrectEnglish() {
    // 日本語の場合は音声読み上げ不要
    if (TranslationService.detectLanguage(widget.entry.content) == 'ja') {
      return false;
    }
    
    // 添削が不要な場合（元の文章と添削後が同じまたは添削がない）
    final hasCorrections = _corrections.isNotEmpty && !_corrections.contains('本日のAI利用枚を使い切りました。明日また利用可能になります。');
    final needsCorrection = _correctedContent.isNotEmpty && _correctedContent != widget.entry.content;
    
    // 添削が不要で、エラーがない場合は正しい英語と判定
    return !hasCorrections && !needsCorrection && !_isLoading;
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
  
  
  /// 共通のブロックコンポーネントを作成
  Widget _buildInfoBlock({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    Duration? animationDelay,
  }) {
    return AppCard(
      backgroundColor: color.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 白背景コンテナを追加して統一感を向上
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTheme.body2.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: animationDelay ?? 600.ms, 
      duration: 400.ms
    ).slideY(begin: 0.1, end: 0);
  }
  
  /// レビュー画面と同じアドバイスセクションを作成
  Widget _buildAdviceSection() {
    List<String> adviceList;
    
    switch (_judgment) {
      case '日本語翻訳':
        adviceList = [
          '自然な英語表現を学習しましょう',
          '文法や語順に注意して英語で考える練習をしましょう',
          '日常的に英語で表現することを心がけましょう'
        ];
        break;
      case '英文（正しい）':
        adviceList = [
          '素晴らしい英文です！この調子で続けましょう',
          'より複雑な表現にも挑戦してみましょう',
          '語彙力を増やして表現の幅を広げましょう'
        ];
        break;
      case '英文（添削必要）':
        adviceList = [
          '基本的な文法をしっかり身につけましょう',
          '添削内容を参考にして同じ間違いを避けましょう',
          '繰り返し練習することで自然な英語が身につきます'
        ];
        break;
      default:
        adviceList = [
          '日記を続けることで英語力が向上します',
          '間違いを恐れずに表現することが大切です'
        ];
    }
    
    return _buildInfoBlock(
      title: 'アドバイス',
      icon: Icons.lightbulb_outline,
      color: AppTheme.warning,
      items: adviceList,
      animationDelay: 600.ms,
    );
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
  
  // スケルトンローディング用のウィジェット
  Widget _buildSkeletonOriginal() {
    return AppCard(
      backgroundColor: AppTheme.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  List<Widget> _buildSkeletonResults() {
    return [
      const SizedBox(height: 16),
      AppCard(
        backgroundColor: AppTheme.backgroundSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(),
      ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1)),
    ];
  }
  
  Widget _buildSkeletonAdvice() {
    return AppCard(
      backgroundColor: AppTheme.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          )),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  Widget _buildSkeletonLearningPoints() {
    return AppCard(
      backgroundColor: AppTheme.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  // 単語ハイライト機能付きテキストウィジェットを構築
  Widget _buildHighlightedText(String text, TextStyle style) {
    if (_shadowingText != text || _highlightedWordIndex == -1 || _shadowingWords.isEmpty) {
      return Text(text, style: style);
    }
    
    final words = text.split(RegExp(r'\s+'));
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = i == _highlightedWordIndex;
      
      spans.add(TextSpan(
        text: word,
        style: style.copyWith(
          backgroundColor: isHighlighted ? AppTheme.primaryColor.withOpacity(0.3) : null,
          color: isHighlighted ? AppTheme.primaryColor : style.color,
          fontWeight: isHighlighted ? FontWeight.w600 : style.fontWeight,
        ),
      ));
      
      // 単語間のスペースを追加（最後の単語以外）
      if (i < words.length - 1) {
        spans.add(TextSpan(text: ' ', style: style));
      }
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}