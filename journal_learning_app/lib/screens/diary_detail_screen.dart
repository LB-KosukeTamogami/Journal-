import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';
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
        final result = await GroqService.correctAndTranslate(
          widget.entry.content,
          targetLanguage: detectedLang == 'ja' ? 'en' : 'ja',
        );
        
        setState(() {
          _correctedContent = result['corrected'] ?? widget.entry.content;
          _translatedContent = translationResult.success ? translationResult.translatedText : (result['translation'] ?? '');
          _corrections = List<String>.from(result['improvements'] ?? []);
          _learnedPhrases = List<String>.from(result['learned_phrases'] ?? []);
          _isLoading = false;
        });
      } catch (groqError) {
        // Groq API失敗時は翻訳サービスの結果のみ使用
        setState(() {
          _correctedContent = widget.entry.content;
          _translatedContent = translationResult.success ? translationResult.translatedText : '翻訳を読み込めませんでした';
          _corrections = [];
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
                  color: AppTheme.primaryBlue,
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
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
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
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '元の文章',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInteractiveText(widget.entry.content, widget.entry.originalLanguage),
                const SizedBox(height: 12),
                // 元の文章の和訳（英語の場合のみ表示）
                if (TranslationService.detectLanguage(widget.entry.content) == 'en')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '日本語訳',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _translatedContent.isNotEmpty 
                              ? _translatedContent 
                              : '翻訳を読み込み中...',
                          style: AppTheme.body2.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
                child: AppCard(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.entry.wordCount} words',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                      Text(
                        '${widget.entry.learnedWords.length} 単語',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 添削結果/翻訳結果
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      TranslationService.detectLanguage(widget.entry.content) == 'ja' ? Icons.translate : Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.detectLanguage(widget.entry.content) == 'ja' ? '英語翻訳' : '添削結果',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
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
                      color: AppTheme.success.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    TranslationService.detectLanguage(widget.entry.content) == 'ja' ? _translatedContent : _correctedContent,
                    style: AppTheme.body1.copyWith(
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 修正箇所（英語の場合のみ）
          if (TranslationService.detectLanguage(widget.entry.content) != 'ja' && _corrections.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: AppTheme.warning.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '修正箇所',
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                            color: AppTheme.warning,
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
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
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
}