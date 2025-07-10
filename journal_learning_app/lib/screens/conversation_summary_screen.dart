import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/conversation_message.dart';
import '../services/gemini_service.dart';
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
  List<String> _keyPhrases = [];
  List<String> _newWords = [];
  List<String> _corrections = [];

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
        setState(() {
          _summary = analysis['summary'] ?? '会話の要約を生成できませんでした。';
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
          const SizedBox(height: 16),
          Text(
            _summary,
            style: AppTheme.body1.copyWith(
              height: 1.6,
            ),
          ),
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
                '使用した単語・フレーズ',
                style: AppTheme.headline3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // キーフレーズ
          if (_keyPhrases.isNotEmpty) ...[
            Text(
              'キーフレーズ',
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
    return Container(
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
    // 会話の内容を基に日記の初期テキストを生成
    final buffer = StringBuffer();
    
    if (widget.topic != null) {
      buffer.writeln('Today I practiced English conversation about ${widget.topic}.');
      buffer.writeln();
    }
    
    if (_keyPhrases.isNotEmpty) {
      buffer.writeln('I learned these phrases:');
      for (final phrase in _keyPhrases.take(3)) {
        buffer.writeln('- $phrase');
      }
      buffer.writeln();
    }
    
    buffer.writeln(_summary);
    
    return buffer.toString();
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