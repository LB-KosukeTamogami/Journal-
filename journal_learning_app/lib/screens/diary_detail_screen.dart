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
    _tabController.addListener(() {
      setState(() {});
    });
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
      
      // Groq APIで添削と翻訳を実行
      final result = await GroqService.correctAndTranslate(
        widget.entry.content,
        targetLanguage: detectedLang == 'ja' ? 'en' : 'ja',
      );
      
      setState(() {
        _correctedContent = result['corrected'] ?? widget.entry.content;
        _translatedContent = result['translation'] ?? '';
        _corrections = List<String>.from(result['improvements'] ?? []);
        _learnedPhrases = List<String>.from(result['learned_phrases'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _correctedContent = widget.entry.content;
        _translatedContent = widget.entry.translatedContent ?? '';
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
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '日記',
                            style: AppTheme.body1.copyWith(
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.entry.originalLanguage == 'ja' ? '翻訳' : '添削',
                            style: AppTheme.body1.copyWith(
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // タブビュー
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDiaryTab(),
                      _buildTranslationTab(),
                    ],
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
                // 元の文章の和訳
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
                        widget.entry.originalLanguage == 'ja' ? widget.entry.content : _translatedContent,
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
          
          // 翻訳/添削結果
          AppCard(
            backgroundColor: AppTheme.success.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.entry.originalLanguage == 'ja' ? Icons.translate : Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.entry.originalLanguage == 'ja' ? '英語翻訳' : '添削後',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInteractiveText(
                  widget.entry.originalLanguage == 'ja' ? _translatedContent : _correctedContent,
                  widget.entry.originalLanguage == 'ja' ? 'en' : widget.entry.originalLanguage,
                ),
                const SizedBox(height: 12),
                // 添削後の和訳
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
                        widget.entry.originalLanguage == 'ja' 
                            ? _correctedContent
                            : _translatedContent,
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
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 統計情報
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  backgroundColor: AppTheme.info.withOpacity(0.05),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.entry.wordCount} words',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.info,
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
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
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
                      widget.entry.originalLanguage == 'ja' ? Icons.translate : Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.entry.originalLanguage == 'ja' ? '英語翻訳' : '添削結果',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInteractiveText(
                  widget.entry.originalLanguage == 'ja' ? _translatedContent : _correctedContent,
                  widget.entry.originalLanguage == 'ja' ? 'en' : widget.entry.originalLanguage,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // 修正箇所（英語の場合のみ）
          if (widget.entry.originalLanguage != 'ja' && _corrections.isNotEmpty) ...[
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
    final words = text.split(' ');
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      
      // 単語の翻訳候補を取得
      final suggestions = TranslationService.suggestTranslations(cleanWord);
      final hasTranslation = suggestions.isNotEmpty && cleanWord.isNotEmpty;
      
      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: hasTranslation
                ? () {
                    final translation = suggestions[cleanWord.toLowerCase()] ?? '';
                    _showWordDetail(cleanWord, translation);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: hasTranslation
                    ? AppTheme.primaryBlue.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                word,
                style: AppTheme.body1.copyWith(
                  color: hasTranslation ? AppTheme.primaryBlue : AppTheme.textPrimary,
                  height: 1.6,
                  fontWeight: hasTranslation ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
      
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    
    return Text.rich(
      TextSpan(children: spans),
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
              '単語の意味',
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
                ],
              ),
            ),
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