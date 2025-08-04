import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import '../widgets/word_by_word_player.dart';
import '../widgets/integrated_shadowing_player.dart';
import 'diary_creation_screen.dart';

// Local model for extracted phrase info
class ExtractedPhraseInfo {
  final String text;
  final String translation;
  final bool isPhrase;
  final int startIndex;
  final int endIndex;

  ExtractedPhraseInfo({
    required this.text,
    required this.translation,
    required this.isPhrase,
    required this.startIndex,
    required this.endIndex,
  });
}

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
  late TextEditingController _transcriptionController;
  bool _isLoading = true;
  String _correctedContent = '';
  String _translatedContent = '';
  String _judgment = '';
  List<String> _corrections = [];
  List<String> _learnedPhrases = [];
  List<ExtractedPhraseInfo> _extractedWords = [];
  Set<String> _savedWords = {};
  String? _shadowingText;
  String? _shadowingTitle;
  List<String> _shadowingWords = [];
  int _highlightedWordIndex = -1;
  final Map<String, String> _wordDefinitions = {};
  
  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'between', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why',
    'how', 'all', 'both', 'each', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 's', 't', 'can', 'will', 'just', 'don', 'should',
    'now', 'is', 'are', 'was', 'were', 'been', 'be', 'have', 'has', 'had',
    'do', 'does', 'did', 'would', 'could', 'may', 'might',
    'must', 'shall', 'need', 'ought', 'dare', 'used',
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transcriptionController = TextEditingController();
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
      // Check cache first
      final cachedTranslation = await SupabaseService.getTranslationCache(widget.entry.id);
      
      if (cachedTranslation != null) {
        setState(() {
          _translatedContent = cachedTranslation['translated_text'] ?? '';
          _correctedContent = cachedTranslation['corrected_text'] ?? widget.entry.content;
          _corrections = List<String>.from(cachedTranslation['improvements'] ?? []);
          _judgment = cachedTranslation['judgment'] ?? '';
          _learnedPhrases = List<String>.from(cachedTranslation['learned_phrases'] ?? []);
          
          final extractedWordsData = cachedTranslation['extracted_words'] ?? [];
          _extractedWords = extractedWordsData.map<ExtractedPhraseInfo>((data) => ExtractedPhraseInfo(
            text: data['text'] ?? '',
            translation: data['translation'] ?? '',
            isPhrase: data['isPhrase'] ?? false,
            startIndex: 0,
            endIndex: 0,
          )).toList();
          
          _isLoading = false;
        });
      } else {
        // If no cache, try to get translation
        final detectedLang = TranslationService.detectLanguage(widget.entry.content);
        String targetLanguage = detectedLang == 'ja' ? 'en' : 'ja';
        
        if (detectedLang == 'mixed') {
          targetLanguage = 'en';
        }
        
        String translatedText = '';
        String correctedContent = widget.entry.content;
        List<String> corrections = [];
        String judgment = '';
        
        try {
          // Try Gemini API
          final geminiResult = await GeminiService.reviewDiary(widget.entry.content);
          
          if (geminiResult != null) {
            translatedText = geminiResult['translated'] ?? '';
            correctedContent = geminiResult['corrected'] ?? widget.entry.content;
            corrections = List<String>.from(geminiResult['improvements'] ?? []);
            judgment = geminiResult['judgment'] ?? '';
          }
        } catch (e) {
          // Fallback to simple translation
          translatedText = await TranslationService.translate(
            text: widget.entry.content,
            targetLanguage: targetLanguage,
            sourceLanguage: detectedLang == 'mixed' ? 'auto' : detectedLang,
          );
        }
        
        // Extract words
        final words = _extractWordsFromText(widget.entry.content);
        final extractedWords = words.map((word) => ExtractedPhraseInfo(
          text: word,
          translation: TranslationService.suggestTranslations(word)[word.toLowerCase()] ?? '',
          isPhrase: false,
          startIndex: 0,
          endIndex: 0,
        )).toList();
        
        setState(() {
          _translatedContent = translatedText;
          _correctedContent = correctedContent;
          _corrections = corrections;
          _judgment = judgment;
          _extractedWords = extractedWords;
          _isLoading = false;
        });
        
        // Save to cache if we have Supabase connection
        if (SupabaseService.isAvailable && AuthService.currentUser != null) {
          try {
            await SupabaseService.saveTranslationCache(
              diaryEntryId: widget.entry.id,
              translatedText: translatedText,
              correctedText: correctedContent,
              improvements: corrections,
              judgment: judgment,
              learnedPhrases: [],
              extractedWords: extractedWords.map((w) => {
                'text': w.text,
                'translation': w.translation,
                'isPhrase': w.isPhrase.toString(),
              }).toList(),
              learnedWords: [],
            );
          } catch (e) {
            print('Failed to save translation cache: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading translation data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildDiaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.entry.title,
            style: AppTheme.display3,
          ),
          const SizedBox(height: 8),
          
          // Date and mood
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('yyyy年M月d日 (E)', 'ja').format(widget.entry.createdAt),
                style: AppTheme.caption,
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.mood,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                widget.entry.mood,
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Content
          AppCard(
            child: Text(
              widget.entry.content,
              style: AppTheme.body1,
            ),
          ),
          
          // Transcription section
          if (_correctedContent.isNotEmpty && _correctedContent != widget.entry.content) ...[
            const SizedBox(height: 24),
            Text(
              '写経',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _transcriptionController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'ここに添削後の英文を書き写してください...',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Learned words
          if (widget.entry.learnedWords.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '学習した単語',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.entry.learnedWords.map((word) {
                return Chip(
                  label: Text(word),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTranslationTab() {
    final detectedLang = TranslationService.detectLanguage(widget.entry.content);
    final isJapanese = detectedLang == 'ja';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Translation card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isJapanese ? Icons.translate : Icons.check_circle,
                      color: isJapanese ? Theme.of(context).colorScheme.secondary : AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isJapanese ? '英語翻訳' : 'すでに英語です',
                      style: AppTheme.heading2,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _translatedContent.isNotEmpty ? _translatedContent : widget.entry.content,
                  style: AppTheme.body1,
                ),
              ],
            ),
          ),
          
          // Corrections
          if (_corrections.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '添削ポイント',
                        style: AppTheme.heading2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._corrections.map((correction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: AppTheme.body2),
                        Expanded(
                          child: Text(correction, style: AppTheme.body2),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          
          // Extracted words
          if (_extractedWords.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '抽出された単語',
                        style: AppTheme.heading2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _extractedWords.map((info) {
                      final isSaved = _savedWords.contains(info.text.toLowerCase());
                      return ActionChip(
                        label: Text(info.text),
                        avatar: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                        ),
                        onPressed: () => _toggleWordSave(info),
                        backgroundColor: isSaved 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: Colors.grey.withOpacity(0.1));
  }
  
  Future<void> _toggleWordSave(ExtractedPhraseInfo info) async {
    final isSaved = _savedWords.contains(info.text.toLowerCase());
    
    if (isSaved) {
      // Remove from saved
      final words = await StorageService.getWords();
      final wordToRemove = words.firstWhere(
        (w) => w.english.toLowerCase() == info.text.toLowerCase(),
        orElse: () => Word(
          id: '',
          english: '',
          japanese: '',
          category: WordCategory.other,
          createdAt: DateTime.now(),
          masteryLevel: 0,
          reviewCount: 0,
          lastReviewedAt: DateTime.now(),
        ),
      );
      
      if (wordToRemove.id.isNotEmpty) {
        await StorageService.deleteWord(wordToRemove.id);
        setState(() {
          _savedWords.remove(info.text.toLowerCase());
        });
      }
    } else {
      // Add to saved
      final word = Word(
        id: const Uuid().v4(),
        english: info.text,
        japanese: info.translation.isNotEmpty ? info.translation : await _getTranslation(info.text),
        category: WordCategory.other,  // TODO: Implement proper category detection
        createdAt: DateTime.now(),
        masteryLevel: 0,
        reviewCount: 0,
        lastReviewedAt: null,
      );
      
      await StorageService.saveWord(word);
      setState(() {
        _savedWords.add(info.text.toLowerCase());
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSaved ? '単語を削除しました' : '単語を保存しました'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  Future<String> _getTranslation(String word) async {
    if (_wordDefinitions.containsKey(word)) {
      return _wordDefinitions[word]!;
    }
    
    try {
      final translated = await TranslationService.translate(
        text: word,
        targetLanguage: 'ja',
        sourceLanguage: 'en',
      );
      _wordDefinitions[word] = translated;
      return translated;
    } catch (e) {
      return '[翻訳エラー]';
    }
  }
  
  List<String> _extractWordsFromText(String text) {
    final words = <String>{};
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final wordList = cleanText.split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_stopWords.contains(word))
        .toList();
    
    words.addAll(wordList);
    final sortedWords = words.toList()..sort();
    
    return sortedWords;
  }
  
  String _getWordCategory(String word) {
    if (word.endsWith('ing') || word.endsWith('ed')) {
      return 'verb';
    } else if (word.endsWith('ly')) {
      return 'adverb';
    } else if (word.endsWith('ion') || word.endsWith('ity') || word.endsWith('ness')) {
      return 'noun';
    } else if (word.endsWith('ful') || word.endsWith('less') || word.endsWith('ous')) {
      return 'adjective';
    }
    return 'general';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('M月d日 (E)', 'ja').format(widget.entry.createdAt),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryCreationScreen(
                    existingEntry: widget.entry,
                  ),
                ),
              );
              
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '日記'),
                    Tab(text: '翻訳'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
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
}