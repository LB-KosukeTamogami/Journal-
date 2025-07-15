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
  String _judgment = '';
  String _outputText = '';
  String _originalText = '';
  List<String> _corrections = [];
  List<String> _improvements = [];
  List<Map<String, String>> _learnedWords = [];
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
        _judgment = result['judgment'] ?? '';
        _detectedLanguage = result['detected_language'] ?? widget.detectedLanguage;
        _outputText = result['corrected'] ?? widget.entry.content;
        _originalText = widget.entry.content;
        _corrections = List<String>.from(result['corrections'] ?? []);
        _improvements = List<String>.from(result['improvements'] ?? []);
        
        // learned_wordsを処理
        if (result['learned_words'] != null) {
          _learnedWords = List<Map<String, String>>.from(result['learned_words']);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('[DiaryReviewScreen] Error processing content: $e');
      // エラー時はフォールバック
      setState(() {
        _judgment = 'エラー';
        _detectedLanguage = widget.detectedLanguage;
        _outputText = widget.entry.content;
        _originalText = widget.entry.content;
        _isLoading = false;
      });
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
          'レビュー結果',
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
                  // 判定結果の表示
                  _buildJudgmentSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 元の文章
                  _buildOriginalSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 結果文章（翻訳・添削後の英文）
                  _buildResultSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 添削コメント（必要な場合のみ）
                  if (_corrections.isNotEmpty || _improvements.isNotEmpty)
                    _buildCorrectionsSection(),
                  
                  if (_corrections.isNotEmpty || _improvements.isNotEmpty)
                    const SizedBox(height: 20),
                  
                  // 重要単語（ある場合）
                  if (_learnedWords.isNotEmpty)
                    _buildLearningWordsSection(),
                  
                  if (_learnedWords.isNotEmpty)
                    const SizedBox(height: 20),
                  
                  // 単語を学習カードに追加するボタン
                  if (_learnedWords.isNotEmpty)
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
          
          // すべての重要単語を学習カードとして保存
          int addedCount = 0;
          for (final wordData in _learnedWords) {
            final english = wordData['english'] ?? '';
            final japanese = wordData['japanese'] ?? '';
            
            if (english.isNotEmpty && japanese.isNotEmpty) {
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
                  category: WordCategory.other,
                );
                
                // StorageServiceを通じてSupabaseに保存
                await StorageService.saveWord(word);
                addedCount++;
                print('[DiaryReviewScreen] Added word to storage: $english - $japanese');
              } catch (e) {
                print('[DiaryReviewScreen] Error saving word: $e');
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
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_card),
        label: Text('学習カードにすべて追加', style: AppTheme.button),
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


  // 判定結果の表示
  Widget _buildJudgmentSection() {
    String judgmentDisplay;
    Color judgmentColor;
    IconData judgmentIcon;

    switch (_judgment) {
      case '日本語翻訳':
        judgmentDisplay = '日本語 → 英語翻訳';
        judgmentColor = AppTheme.primaryBlue;
        judgmentIcon = Icons.translate;
        break;
      case '英文（正しい）':
        judgmentDisplay = '正しい英文です';
        judgmentColor = AppTheme.success;
        judgmentIcon = Icons.check_circle;
        break;
      case '英文（添削必要）':
        judgmentDisplay = '英文を添削しました';
        judgmentColor = AppTheme.warning;
        judgmentIcon = Icons.edit_note;
        break;
      default:
        judgmentDisplay = '処理中...';
        judgmentColor = AppTheme.textSecondary;
        judgmentIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: judgmentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: judgmentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(judgmentIcon, color: judgmentColor, size: 24),
          const SizedBox(width: 12),
          Text(
            judgmentDisplay,
            style: AppTheme.body1.copyWith(
              color: judgmentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // 結果文章（翻訳・添削後の英文）とTTSボタン
  Widget _buildResultSection() {
    return AppCard(
      backgroundColor: AppTheme.success.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _judgment == '日本語翻訳' ? '英訳' : '英文',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
              const Spacer(),
              // TTS ボタン
              TextToSpeechButton(
                text: _outputText,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            _outputText,
            style: AppTheme.body1.copyWith(
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // 添削コメント
  Widget _buildCorrectionsSection() {
    final allCorrections = [..._corrections, ..._improvements];
    
    return AppCard(
      backgroundColor: AppTheme.warning.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '添削コメント',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...allCorrections.map((correction) => Padding(
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
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // 重要単語
  Widget _buildLearningWordsSection() {
    return AppCard(
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
                '重要単語',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _learnedWords.map((wordData) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wordData['english'] ?? '',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    wordData['japanese'] ?? '',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.info.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLearningPointsSection() {
    // デフォルトの学習ポイントを表示
    final points = _learnedWords.isNotEmpty 
        ? ['単語の意味を確認しながら学習しましょう', '繰り返し復習することで定着します', '文脈から単語の使い方を理解しましょう']
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