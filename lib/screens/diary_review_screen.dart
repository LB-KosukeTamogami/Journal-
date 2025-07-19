import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../models/flashcard.dart';
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
  String _translatedText = ''; // 翻訳文を保存
  List<String> _corrections = [];
  List<String> _improvements = [];
  List<Map<String, String>> _learnedWords = [];
  bool _isLoading = true;
  String _detectedLanguage = '';
  bool _isAllAddedToCards = false;
  Set<String> _addedWords = {}; // 追加された単語を管理
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
    _processContent();
  }
  
  @override
  void dispose() {
    _transcriptionController.dispose();
    super.dispose();
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
        _translatedText = result['translation'] ?? ''; // 翻訳文を保存
        _corrections = List<String>.from(result['corrections'] ?? []);
        _improvements = List<String>.from(result['improvements'] ?? []);
        
        // learned_wordsを処理（フィルタリングを適用）
        if (result['learned_words'] != null) {
          final allWords = List<Map<String, String>>.from(result['learned_words']);
          _learnedWords = allWords.where((wordData) {
            final english = (wordData['english'] ?? '').toLowerCase();
            return english.length >= 3 && // 3文字以上
                   !_stopWords.contains(english) && // ストップワードを除外
                   RegExp(r'^[a-zA-Z]+$').hasMatch(english); // 英字のみ
          }).toList();
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
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                // レビュー画面から日記作成画面に結果を返す
                print('[DiaryReviewScreen] Completion button pressed, returning to diary creation screen');
                Navigator.of(context).pop(true);
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
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 判定結果の表示
                  _isLoading ? _buildSkeletonJudgment() : _buildJudgmentSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 1. 元の文章
                  _buildOriginalSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 2. 翻訳または添削の文章（条件に応じて表示）
                  if (_shouldShowTranslationOrCorrection())
                    _isLoading ? _buildSkeletonResult() : _buildTranslationOrCorrectionSection(),
                  
                  if (_shouldShowTranslationOrCorrection())
                    const SizedBox(height: 20),
                  
                  // 3. 写経セクション（翻訳・添削が成功した場合のみ、正しい英文の場合は除く）
                  if (_shouldShowTranslationOrCorrection() && !_isLoading && _judgment != '英文（正しい）')
                    _buildTranscriptionSection(),
                  
                  if (_shouldShowTranslationOrCorrection() && !_isLoading && _judgment != '英文（正しい）')
                    const SizedBox(height: 20),
                  
                  // 4. 添削の解説（添削時のみ）
                  if (_shouldShowCorrectionExplanation())
                    _isLoading ? _buildSkeletonCorrections() : _buildCorrectionExplanationSection(),
                  
                  if (_shouldShowCorrectionExplanation())
                    const SizedBox(height: 20),
                  
                  // 5. アドバイス
                  _isLoading ? _buildSkeletonCorrections() : _buildAdviceSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 6. 重要単語（ある場合）
                  if (_isLoading)
                    _buildSkeletonWords()
                  else if (_learnedWords.isNotEmpty)
                    _buildLearningWordsSection(),
                  
                  if (_isLoading || _learnedWords.isNotEmpty)
                    const SizedBox(height: 20),
                  
                  // 単語を学習カードに追加するボタン
                  if (!_isLoading && _learnedWords.isNotEmpty)
                    _buildAddToCardsButton(),
                ],
              ),
            ),
    );
  }
  
  // 条件判定メソッド
  bool _shouldShowTranslationOrCorrection() {
    return _judgment == '日本語翻訳' || _judgment == '英文（添削必要）';
  }
  
  bool _shouldShowCorrectionExplanation() {
    return _judgment == '英文（添削必要）';
  }
  
  // スケルトンローディング用のウィジェット
  Widget _buildSkeletonJudgment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  Widget _buildSkeletonResult() {
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
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  Widget _buildSkeletonCorrections() {
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
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(2, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
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
  
  Widget _buildSkeletonWords() {
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
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(3, (index) => Container(
              width: 80 + (index * 20).toDouble(),
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            )),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(duration: 1500.ms, color: AppTheme.textSecondary.withOpacity(0.1));
  }
  
  Widget _buildAddToCardsButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.buttonShadow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isAllAddedToCards ? null : () async {
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
                    category: _getWordCategory(english),
                  );
                  
                  // StorageServiceを通じてSupabaseに保存
                  await StorageService.saveWord(word);
                  
                  // 追加された単語としてマーク
                  _addedWords.add(english.toLowerCase());
                  
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
              setState(() {
                _isAllAddedToCards = true;
              });
              
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
          style: _isAllAddedToCards 
            ? AppButtonStyles.primaryButton.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                foregroundColor: MaterialStateProperty.all(AppTheme.primaryColor),
                side: MaterialStateProperty.all(BorderSide(color: AppTheme.primaryColor, width: 2)),
                minimumSize: MaterialStateProperty.all(Size(double.infinity, 56)),
              )
            : AppButtonStyles.primaryButton.copyWith(
                minimumSize: MaterialStateProperty.all(Size(double.infinity, 56)),
              ),
          icon: Icon(
            _isAllAddedToCards ? Icons.check_circle : Icons.add_card,
            color: _isAllAddedToCards ? AppTheme.primaryColor : Colors.white,
          ),
          label: Text(
            _isAllAddedToCards ? '学習カードに追加済み' : '学習カードにすべて追加',
            style: AppTheme.button.copyWith(
              color: _isAllAddedToCards ? AppTheme.primaryColor : Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOriginalSection() {
    // 英語（正しい）の場合は元の文章に音声読み上げボタンを表示
    final showTTS = _judgment == '英文（正しい）';
    // 英語の場合は日本語翻訳を表示
    final isEnglish = _detectedLanguage == 'en' || _detectedLanguage == 'mixed';
    
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
              if (showTTS) ...[
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
          // 英語の場合、日本語訳を透明背景のコンテナで表示
          if (isEnglish && _translatedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
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
                  Text(
                    _translatedText,
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
      case 'エラー':
      case 'エラーが発生しました':
      case 'API設定エラー':
      case 'レスポンス解析エラー':
      case 'ネットワークエラー':
      case 'API認証エラー':
      case 'API利用制限に達しました':
        judgmentDisplay = _judgment;
        judgmentColor = AppTheme.error;
        judgmentIcon = Icons.error_outline;
        break;
      default:
        // 想定外の値の場合
        judgmentDisplay = '処理中';
        judgmentColor = AppTheme.textSecondary;
        judgmentIcon = Icons.info_outline;
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allCorrections.map((correction) => Padding(
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
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // 抽出した単語
  Widget _buildLearningWordsSection() {
    return AppCard(
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '抽出した単語',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _learnedWords.map((wordData) {
              final english = wordData['english'] ?? '';
              final japanese = wordData['japanese'] ?? '';
              final isAdded = _addedWords.contains(english.toLowerCase());
              
              return GestureDetector(
                onTap: () {
                  // モーダルを下から表示（日記詳細画面と同じデザインに統一）
                  // 既存の追加済み状態を初期値として設定
                  bool isAddedToFlashcard = isAdded;
                  bool isAddedToVocabulary = false;
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setModalState) {
                        
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
                                          english,
                                          style: AppTheme.headline2,
                                        ),
                                        const SizedBox(height: 8),
                                        // 日本語の意味
                                        Text(
                                          japanese,
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
                                      _getPartOfSpeech(english),
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
                                                (w) => w.english.toLowerCase() == english.toLowerCase(),
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
                                                  _addedWords.remove(english.toLowerCase());
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
                                              
                                              // メインの状態も更新
                                              setState(() {
                                                _addedWords.add(english.toLowerCase());
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
                                                (card) => card.word.toLowerCase() == english.toLowerCase(),
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
                                                word: english,
                                                meaning: japanese,
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
                  decoration: BoxDecoration(
                    color: isAdded
                        ? AppTheme.success.withOpacity(0.05)
                        : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdded
                          ? AppTheme.success.withOpacity(0.5)
                          : AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
                        child: Text(
                          english,
                          style: AppTheme.body2.copyWith(
                            color: isAdded ? AppTheme.success : AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8, right: 12),
                        child: Icon(
                          isAdded ? Icons.check : Icons.add_card,
                          color: isAdded ? AppTheme.success : AppTheme.primaryBlue,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
  
  // 2. 翻訳または添削の文章セクション
  Widget _buildTranslationOrCorrectionSection() {
    String sectionTitle;
    Color sectionColor;
    IconData sectionIcon;
    
    if (_judgment == '日本語翻訳') {
      sectionTitle = '英語翻訳';
      sectionColor = AppTheme.primaryBlue;
      sectionIcon = Icons.translate;
    } else {
      sectionTitle = '添削後';
      sectionColor = AppTheme.success;
      sectionIcon = Icons.check_circle;
    }
    
    return AppCard(
      backgroundColor: sectionColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                sectionIcon,
                color: sectionColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: sectionColor,
                ),
              ),
              const Spacer(),
              // 音声読み上げボタン（常に表示）
              TextToSpeechButton(
                text: _outputText,
                size: 20,
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
                color: sectionColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: SelectableText(
              _outputText,
              style: AppTheme.body1.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ),
          // 英文添削の場合、日本語訳を透明背景のコンテナで表示
          if (_judgment == '英文（添削必要）' && _translatedText.isNotEmpty) ...[
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
                    _translatedText,
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
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
  
  // 3. 添削の解説セクション（添削時のみ）
  Widget _buildCorrectionExplanationSection() {
    final allCorrections = [..._corrections, ..._improvements];
    
    return AppCard(
      backgroundColor: AppTheme.info.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
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
              children: allCorrections.map((correction) => Padding(
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
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
  
  // 4. アドバイスセクション
  Widget _buildAdviceSection() {
    List<String> adviceList = [];
    
    // 文章の長さと内容を分析
    final wordCount = widget.entry.content.split(' ').where((word) => word.isNotEmpty).length;
    final sentenceCount = widget.entry.content.split(RegExp(r'[.!?。！？]')).where((s) => s.trim().isNotEmpty).length;
    final hasQuestionMark = widget.entry.content.contains('?') || widget.entry.content.contains('？');
    final hasExclamation = widget.entry.content.contains('!') || widget.entry.content.contains('！');
    
    switch (_judgment) {
      case '日本語翻訳':
        // 日本語から英語への翻訳時のアドバイス
        adviceList.add('英語で日記を書く練習を続けることで、自然な英語表現が身につきます。');
        
        if (wordCount < 20) {
          adviceList.add('もう少し詳細を追加してみましょう。例えば、感情や理由、具体的な状況を説明すると良いでしょう。');
        } else if (wordCount > 50) {
          adviceList.add('詳細な記述ができています！段落を分けて構成を整理すると、さらに読みやすくなります。');
        }
        
        if (sentenceCount == 1) {
          adviceList.add('複数の文で構成してみましょう。接続詞（and, but, because など）を使って文をつなげる練習をしましょう。');
        }
        
        adviceList.add('翻訳された英文を音読して、自然なリズムとイントネーションを身につけましょう。');
        break;
        
      case '英文（正しい）':
        // 正しい英文の場合のアドバイス
        adviceList.add('素晴らしい英文です！この調子で毎日続けることが上達への近道です。');
        
        if (wordCount < 30) {
          adviceList.add('さらに詳細を追加して、より豊かな表現に挑戦してみましょう。');
        }
        
        if (!hasQuestionMark && !hasExclamation) {
          adviceList.add('疑問文や感嘆文も使って、より表現豊かな文章を書いてみましょう。');
        }
        
        // 使用された時制に基づくアドバイス
        if (widget.entry.content.contains(RegExp(r'\b(was|were|did|had)\b'))) {
          adviceList.add('過去形の使用が適切です。現在完了形（have/has + 過去分詞）も学習して、時制の幅を広げましょう。');
        }
        
        adviceList.add('新しい語彙や慣用表現を取り入れて、表現の幅をさらに広げていきましょう。');
        break;
        
      case '英文（添削必要）':
        // 添削が必要な英文の場合のアドバイス
        if (_corrections.isNotEmpty || _improvements.isNotEmpty) {
          final totalCorrections = _corrections.length + _improvements.length;
          
          if (totalCorrections == 1) {
            adviceList.add('ほぼ正しい英文が書けています！添削箇所を確認して、同じ間違いを避けるようにしましょう。');
          } else if (totalCorrections <= 3) {
            adviceList.add('基本的な英文は書けています。添削内容を復習して、より自然な表現を身につけましょう。');
          } else {
            adviceList.add('添削箇所が多いですが、挑戦する姿勢が素晴らしいです！一つずつ改善していきましょう。');
          }
        }
        
        // 文法的なアドバイス
        if (widget.entry.content.toLowerCase().contains(' i ')) {
          adviceList.add('主語「I」は常に大文字で書きましょう。基本的なルールを意識することが大切です。');
        }
        
        if (sentenceCount > 3) {
          adviceList.add('複数の文を書けているのは良いことです。接続詞や関係代名詞を使って、文の関連性を明確にしましょう。');
        }
        
        adviceList.add('添削された文章を声に出して読み、正しい表現を体に覚えさせましょう。');
        adviceList.add('同じテーマで再度書いてみると、学習効果が高まります。');
        break;
        
      default:
        adviceList = [
          '日記を続けることで英語力が向上します。',
          '間違いを恐れずに表現することが大切です。',
          '毎日少しずつでも英語に触れる時間を作りましょう。'
        ];
    }
    
    return AppCard(
      backgroundColor: AppTheme.warning.withOpacity(0.05),
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
                '文章構成のアドバイス',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
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
              children: adviceList.map((advice) => Padding(
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
                        advice,
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
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
  
  // 写経セクション
  Widget _buildTranscriptionSection() {
    return AppCard(
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
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
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
}