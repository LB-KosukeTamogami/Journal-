import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../widgets/text_to_speech_button.dart';

class DiaryReviewScreen extends StatefulWidget {
  final DiaryEntry entry;
  final String detectedLanguage;

  const DiaryReviewScreen({
    super.key,
    required this.entry,
    required this.detectedLanguage,
  });

  @override
  State<DiaryReviewScreen> createState() => _DiaryReviewScreenState();
}

class _DiaryReviewScreenState extends State<DiaryReviewScreen> {
  String _translatedContent = '';
  String _correctedContent = '';
  List<String> _corrections = [];
  List<String> _learnedPhrases = [];
  bool _isLoading = true;
  String _detectedLanguage = '';

  @override
  void initState() {
    super.initState();
    _processContent();
  }

  Future<void> _processContent() async {
    try {
      // Gemini APIで添削と翻訳を実行
      final result = await GeminiService.correctAndTranslate(
        widget.entry.content,
        targetLanguage: widget.detectedLanguage == 'ja' ? 'en' : 'ja',
      );

      setState(() {
        _detectedLanguage = result['detected_language'] ?? widget.detectedLanguage;
        _correctedContent = result['corrected'] ?? widget.entry.content;
        _translatedContent = result['translation'] ?? '';
        _corrections = List<String>.from(result['improvements'] ?? []);
        _learnedPhrases = List<String>.from(result['learned_phrases'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      // エラー時はフォールバック
      if (widget.detectedLanguage == 'ja') {
        // 従来の翻訳サービスを使用
        final result = await TranslationService.autoTranslate(widget.entry.content);
        if (result.success) {
          setState(() {
            _translatedContent = result.translatedText;
            _correctedContent = widget.entry.content;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _correctedContent = widget.entry.content;
          _translatedContent = widget.entry.content;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DiaryReviewScreen] Building with entry: ${widget.entry.id}');
    print('[DiaryReviewScreen] Detected language: ${widget.detectedLanguage}');
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        title: Text(
          widget.detectedLanguage == 'ja' ? '翻訳結果' : '添削結果',
          style: AppTheme.headline3,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                // ジャーナル画面（日記一覧）に戻る
                // JournalScreen -> DiaryCreationScreen -> DiaryReviewScreen の順で遷移しているので
                // JournalScreenまで戻る
                print('[DiaryReviewScreen] Completion button pressed, navigating back to journal screen');
                int count = 0;
                Navigator.of(context).popUntil((route) {
                  count++;
                  print('[DiaryReviewScreen] Pop count: $count, route: ${route.settings.name}');
                  return count == 3 || route.isFirst;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                '完了',
                style: AppTheme.button.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    widget.detectedLanguage == 'ja' ? '翻訳中...' : '添削中...',
                    style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 元の文章
                  _buildOriginalSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 翻訳結果または添削結果
                  if (widget.detectedLanguage == 'ja')
                    _buildTranslationSection()
                  else
                    _buildCorrectionSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 学習ポイント
                  _buildLearningPointsSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 単語を学習カードに追加するボタン
                  if (_learnedPhrases.isNotEmpty)
                    _buildAddToCardsButton(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildAddToCardsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // 重要フレーズを単語カードとして保存
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
              ),
            );
          }
        },
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
    ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOriginalSection() {
    return AppCard(
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
          Text(
            widget.entry.content,
            style: AppTheme.body1.copyWith(height: 1.6),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTranslationSection() {
    return AppCard(
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
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '英語翻訳',
                    style: AppTheme.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              TextToSpeechButton(
                text: _translatedContent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _translatedContent,
            style: AppTheme.body1.copyWith(
              height: 1.6,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCorrectionSection() {
    return Column(
      children: [
        // 添削後の文章
        AppCard(
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
                  TextToSpeechButton(
                    text: _correctedContent,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _correctedContent,
                style: AppTheme.body1.copyWith(
                  height: 1.6,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        
        if (_corrections.isNotEmpty) ...[
          const SizedBox(height: 16),
          // 修正箇所
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
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ],
    );
  }

  Widget _buildLearningPointsSection() {
    // 学習したフレーズがある場合はそれを表示、なければデフォルト
    final points = _learnedPhrases.isNotEmpty 
        ? _learnedPhrases
        : widget.detectedLanguage == 'ja' 
            ? [
                '自然な英語表現を学びました',
                '日記を続けることで語彙力が向上します',
                '翻訳結果を参考に英語で考える練習をしましょう',
              ]
            : [
                '文法の基本をしっかり身につけましょう',
                '過去形と現在形の使い分けを意識しましょう',
                '前置詞の使い方に注意して練習しましょう',
              ];

    return AppCard(
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
          ...points.map((point) => Padding(
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
                    point,
                    style: AppTheme.body2.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}