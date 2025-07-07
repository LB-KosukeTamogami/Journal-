import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/diary_entry.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _processContent();
  }

  Future<void> _processContent() async {
    if (widget.detectedLanguage == 'ja') {
      // 日本語の場合は英語に翻訳
      final result = await TranslationService.autoTranslate(widget.entry.content);
      if (result.success) {
        setState(() {
          _translatedContent = result.translatedText;
          _isLoading = false;
        });
      }
    } else {
      // 英語の場合は添削を生成（模擬的）
      _generateCorrections();
    }
  }

  void _generateCorrections() {
    // 模擬的な添削機能
    final content = widget.entry.content;
    final corrections = <String>[];
    String corrected = content;

    // 簡単な文法チェック例
    if (content.contains('I go to school yesterday')) {
      corrections.add('"I go to school yesterday" → "I went to school yesterday" (過去形を使用)');
      corrected = corrected.replaceAll('I go to school yesterday', 'I went to school yesterday');
    }
    
    if (content.contains('I have many friends in school')) {
      corrections.add('"I have many friends in school" → "I have many friends at school" (前置詞の使い分け)');
      corrected = corrected.replaceAll('I have many friends in school', 'I have many friends at school');
    }

    setState(() {
      _correctedContent = corrected;
      _corrections = corrections;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
                ],
              ),
            ),
    );
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
    final points = widget.detectedLanguage == 'ja' 
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