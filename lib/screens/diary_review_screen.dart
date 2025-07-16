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
  List<String> _corrections = [];
  List<String> _improvements = [];
  List<Map<String, String>> _learnedWords = [];
  bool _isLoading = true;
  String _detectedLanguage = '';
  bool _isAllAddedToCards = false;
  Set<String> _addedWords = {}; // 追加された単語を管理
  
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
                  
                  // 3. 添削の解説（添削時のみ）
                  if (_shouldShowCorrectionExplanation())
                    _isLoading ? _buildSkeletonCorrections() : _buildCorrectionExplanationSection(),
                  
                  if (_shouldShowCorrectionExplanation())
                    const SizedBox(height: 20),
                  
                  // 4. アドバイス
                  _isLoading ? _buildSkeletonCorrections() : _buildAdviceSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 5. 重要単語（ある場合）
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
                    category: WordCategory.other,
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
                                                category: WordCategory.other,
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
      sectionTitle = '翻訳';
      sectionColor = AppTheme.primaryBlue;
      sectionIcon = Icons.translate;
    } else {
      sectionTitle = '添削';
      sectionColor = AppTheme.warning;
      sectionIcon = Icons.edit_note;
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
              // 音声読み上げボタン（翻訳・添削時は常に表示）
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
  
  // 3. 添削の解説セクション（添削時のみ）
  Widget _buildCorrectionExplanationSection() {
    final allCorrections = [..._corrections, ..._improvements];
    
    return AppCard(
      backgroundColor: AppTheme.warning.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '添削の解説',
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
  
  // 4. アドバイスセクション
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
    
    return AppCard(
      backgroundColor: AppTheme.info.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'アドバイス',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...adviceList.map((advice) => Padding(
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
                    advice,
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
}