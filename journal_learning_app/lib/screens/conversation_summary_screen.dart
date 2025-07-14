import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/conversation_message.dart';
import '../models/word.dart';
import '../models/flashcard.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../config/api_config.dart';
import 'diary_creation_screen.dart';

class ConversationSummaryScreen extends StatefulWidget {
  final List<ConversationMessage> messages;
  final String? topic;

  const ConversationSummaryScreen({
    super.key,
    required this.messages,
    this.topic,
  });

  @override
  State<ConversationSummaryScreen> createState() => _ConversationSummaryScreenState();
}

class _ConversationSummaryScreenState extends State<ConversationSummaryScreen> {
  bool _isAnalyzing = true;
  String _summary = '';
  String _summaryTranslation = '';
  List<String> _keyPhrases = [];
  List<String> _newWords = [];
  List<String> _corrections = [];
  Map<String, bool> _addedToStudyCards = {};
  Map<String, bool> _addedToVocabulary = {};

  @override
  void initState() {
    super.initState();
    _analyzeConversation();
  }

  Future<void> _analyzeConversation() async {
    try {
      // 会話のテキストを結合
      final conversationText = widget.messages.map((msg) {
        return "${msg.isUser ? 'User' : 'Aco'}: ${msg.text}";
      }).join('\n');

      // Gemini APIを使用して会話を分析
      final analysis = await GeminiService.analyzeConversation(
        conversationText: conversationText,
        messages: widget.messages,
      );

      if (mounted) {
        // 英文の要約を日本語に翻訳
        final translatedSummary = await _translateSummary(analysis['summary'] ?? '');
        
        setState(() {
          _summary = analysis['summary'] ?? '会話の要約を生成できませんでした。';
          _summaryTranslation = translatedSummary;
          _keyPhrases = List<String>.from(analysis['keyPhrases'] ?? []);
          _newWords = List<String>.from(analysis['newWords'] ?? []);
          _corrections = List<String>.from(analysis['corrections'] ?? []);
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = '会話の分析中にエラーが発生しました。';
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showWordDetailModal(String wordOrPhrase) async {
    // 意味を取得
    String translation = await _getWordMeaning(wordOrPhrase);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    color: AppTheme.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 単語/熟語
              Text(
                wordOrPhrase,
                style: AppTheme.headline2.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // 意味
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
                      '意味',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translation,
                      style: AppTheme.body1,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // アクションボタン（縦並び）
              Column(
                children: [
                  // 学習カードに追加
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addedToStudyCards[wordOrPhrase] == true ? null : () async {
                        // 学習カードに追加
                        final now = DateTime.now();
                        final flashcard = Flashcard(
                          id: const Uuid().v4(),
                          word: wordOrPhrase,
                          meaning: translation,
                          createdAt: now,
                          lastReviewed: now,
                          nextReviewDate: now.add(const Duration(days: 1)),
                        );
                        
                        await StorageService.saveFlashcard(flashcard);
                        
                        if (context.mounted) {
                          setState(() {
                            _addedToStudyCards[wordOrPhrase] = true;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('学習カードに追加しました'),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        _addedToStudyCards[wordOrPhrase] == true 
                          ? Icons.check_circle 
                          : Icons.collections_bookmark, 
                        size: 20,
                        color: _addedToStudyCards[wordOrPhrase] == true 
                          ? AppTheme.success 
                          : null,
                      ),
                      label: Text(
                        _addedToStudyCards[wordOrPhrase] == true 
                          ? '学習カードに追加済み' 
                          : '学習カードに追加',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _addedToStudyCards[wordOrPhrase] == true 
                          ? AppTheme.success 
                          : AppTheme.info,
                        side: BorderSide(
                          color: _addedToStudyCards[wordOrPhrase] == true 
                            ? AppTheme.success 
                            : AppTheme.info,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 単語帳に追加
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addedToVocabulary[wordOrPhrase] == true ? null : () async {
                        // 単語帳に追加
                        final word = Word(
                          id: const Uuid().v4(),
                          english: wordOrPhrase,
                          japanese: translation,
                          createdAt: DateTime.now(),
                        );
                        
                        await StorageService.saveWord(word);
                        
                        if (context.mounted) {
                          setState(() {
                            _addedToVocabulary[wordOrPhrase] = true;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('単語帳に追加しました'),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        _addedToVocabulary[wordOrPhrase] == true 
                          ? Icons.check_circle 
                          : Icons.book, 
                        size: 20,
                      ),
                      label: Text(
                        _addedToVocabulary[wordOrPhrase] == true 
                          ? '単語帳に追加済み' 
                          : '単語帳に追加',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _addedToVocabulary[wordOrPhrase] == true 
                          ? AppTheme.success.withOpacity(0.8) 
                          : AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 閉じるボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('閉じる'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('会話の振り返り', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    '会話を分析しています...',
                    style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acoがあなたの学習成果をまとめています',
                    style: AppTheme.body2.copyWith(color: AppTheme.textTertiary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 会話の要約
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // 新しい単語・フレーズ
                  if (_keyPhrases.isNotEmpty || _newWords.isNotEmpty) ...[
                    _buildVocabularyCard(),
                    const SizedBox(height: 16),
                  ],

                  // 修正提案
                  if (_corrections.isNotEmpty) ...[
                    _buildCorrectionsCard(),
                    const SizedBox(height: 16),
                  ],

                  // アクションボタン
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.summarize,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '会話のまとめ',
                    style: AppTheme.headline3,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 英文の要約
          Text(
            _summary,
            style: AppTheme.body1.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          // 日本語訳
          if (_summaryTranslation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _summaryTranslation,
                style: AppTheme.body2.copyWith(
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 300.ms);
  }

  Widget _buildVocabularyCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.info.withOpacity(0.1),
                      AppTheme.info.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.abc,
                  color: AppTheme.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '使用した単語・熟語',
                style: AppTheme.headline3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // キーフレーズ
          if (_keyPhrases.isNotEmpty) ...[
            Text(
              '重要な熟語',
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _keyPhrases.map((phrase) => _buildChip(
                phrase,
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.primaryColor,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // 新しい単語
          if (_newWords.isNotEmpty) ...[
            Text(
              '新しい単語',
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _newWords.map((word) => _buildChip(
                word,
                AppTheme.info.withOpacity(0.1),
                AppTheme.info,
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 100.ms);
  }

  Widget _buildCorrectionsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withOpacity(0.1),
                      AppTheme.warning.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note,
                  color: AppTheme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '学習ポイント',
                style: AppTheme.headline3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_corrections.length, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _corrections[index],
                    style: AppTheme.body2.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 200.ms);
  }

  Widget _buildChip(String text, Color backgroundColor, Color textColor) {
    return InkWell(
      onTap: () => _showWordDetailModal(text),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: textColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTheme.body2.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 日記を作成ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // 会話の内容を日記作成画面に渡す
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryCreationScreen(
                    initialContent: _generateDiaryContent(),
                    conversationSummary: {
                      'summary': _summary,
                      'summaryTranslation': _summaryTranslation,
                      'keyPhrases': _keyPhrases,
                      'newWords': _newWords,
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.edit_note, size: 24),
            label: Text(
              '今日の日記を作成',
              style: AppTheme.body1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().scale(duration: 300.ms, delay: 300.ms),
        
        const SizedBox(height: 12),
        
        // 閉じるボタン
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppTheme.borderColor),
            ),
            child: Text(
              '閉じる',
              style: AppTheme.body1.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().scale(duration: 300.ms, delay: 400.ms),
      ],
    );
  }

  String _generateDiaryContent() {
    // 日記の初期テキストは空にする（会話内容は別カードで表示）
    return '';
  }

  Future<String> _translateSummary(String englishText) async {
    if (englishText.isEmpty) return '';
    
    try {
      // 完全な翻訳を要求するプロンプト
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return '';
      }
      
      final prompt = '''
Translate the following English text to Japanese. 
Provide a COMPLETE and ACCURATE translation, not a summary.
Keep all details and nuances from the original text.

English text:
"$englishText"

Provide only the Japanese translation, nothing else.
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<String> _getWordMeaning(String word) async {
    // 基本的な単語の意味
    final basicMeanings = {
      'hello': 'こんにちは',
      'goodbye': 'さようなら',
      'thank you': 'ありがとう',
      'good morning': 'おはよう',
      'good night': 'おやすみ',
      'today': '今日',
      'tomorrow': '明日',
      'yesterday': '昨日',
      'work': '仕事',
      'home': '家',
      'school': '学校',
      'friend': '友達',
      'family': '家族',
      'love': '愛',
      'like': '好き',
      'happy': '幸せ',
      'sad': '悲しい',
      'tired': '疲れた',
      'hungry': '空腹',
      'food': '食べ物',
      'water': '水',
      'time': '時間',
      'money': 'お金',
      'help': '助け',
      'please': 'お願い',
      'sorry': 'ごめん',
      'yes': 'はい',
      'no': 'いいえ',
      'maybe': 'たぶん',
      'breakfast': '朝食',
      'lunch': '昼食',
      'dinner': '夕食',
      'morning': '朝',
      'afternoon': '午後',
      'evening': '夕方',
      'night': '夜',
      'week': '週',
      'month': '月',
      'year': '年',
      'study': '勉強',
      'learn': '学ぶ',
      'teach': '教える',
      'read': '読む',
      'write': '書く',
      'speak': '話す',
      'listen': '聞く',
      'understand': '理解する',
      'practice': '練習',
      'exercise': '運動',
      'hobby': '趣味',
      'music': '音楽',
      'movie': '映画',
      'book': '本',
      'game': 'ゲーム',
      'sport': 'スポーツ',
      'travel': '旅行',
      'vacation': '休暇',
      'weather': '天気',
      'rain': '雨',
      'snow': '雪',
      'sunny': '晴れ',
      'cloudy': '曇り',
      'hot': '暑い',
      'cold': '寒い',
      'warm': '暖かい',
      'cool': '涼しい',
    };
    
    final lowerWord = word.toLowerCase();
    if (basicMeanings.containsKey(lowerWord)) {
      return basicMeanings[lowerWord]!;
    }
    
    // Gemini APIで翻訳を試みる
    try {
      final result = await GeminiService.correctAndTranslate(
        word,
        targetLanguage: 'ja',
      );
      
      return result['translation'] ?? '意味を取得できませんでした';
    } catch (e) {
      return '意味を取得できませんでした';
    }
  }
}

// AppCard widget (if not already defined elsewhere)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppTheme.backgroundPrimary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}