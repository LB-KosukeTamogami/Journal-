import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/diary_entry.dart';
import '../models/mission.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/mission_service.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import 'diary_review_screen.dart';
import 'conversation_journal_screen.dart';

class DiaryCreationScreen extends StatefulWidget {
  final DiaryEntry? existingEntry;
  final String? initialContent;
  final Map<String, dynamic>? conversationSummary;

  const DiaryCreationScreen({
    Key? key,
    this.existingEntry,
    this.initialContent,
    this.conversationSummary,
  }) : super(key: key);

  @override
  State<DiaryCreationScreen> createState() => _DiaryCreationScreenState();
}

class _DiaryCreationScreenState extends State<DiaryCreationScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  bool _isLoading = false;
  bool _hasChanges = false;
  // リアルタイム翻訳機能を削除
  List<Word> _selectedWords = [];
  String _detectedLanguage = '';
  List<Mission> _todaysMissions = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title;
      _contentController.text = widget.existingEntry!.content;
      _detectLanguage();
    } else if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
      _detectLanguage();
    }
    
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final missions = await MissionService.getTodaysMissions();
    if (mounted) {
      setState(() {
        _todaysMissions = missions;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    
    // 言語検出のみ実行
    _detectLanguage();
  }


  void _detectLanguage() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _detectedLanguage = '';
      });
      return;
    }

    // 言語を検出
    final detectedLang = TranslationService.detectLanguage(content);
    setState(() {
      _detectedLanguage = detectedLang;
    });
  }

  Future<void> _saveDiary() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      _showSnackBar('タイトルと内容を入力してください', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final entry = DiaryEntry(
        id: widget.existingEntry?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        translatedTitle: '',
        translatedContent: '',
        originalLanguage: _detectedLanguage,
        createdAt: widget.existingEntry?.createdAt ?? now,
        updatedAt: now,
        wordCount: _contentController.text.trim().split(' ').length,
        isCompleted: true,
        learnedWords: _selectedWords.map((w) => w.id).toList(),
      );

      await StorageService.saveDiaryEntry(entry);
      
      // 保存した単語も保存
      for (final word in _selectedWords) {
        await StorageService.saveWord(word);
      }

      // ミッションの自動判定
      await MissionService.checkAndUpdateMissions(
        entry: entry,
        newWords: _selectedWords,
      );

      if (mounted) {
        // 編集の場合は通常通り戻る
        if (widget.existingEntry != null) {
          Navigator.pop(context, entry);
          _showSnackBar('日記を更新しました', isError: false);
        } else {
          // 新規作成の場合はレビュー画面に遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryReviewScreen(
                entry: entry,
                detectedLanguage: _detectedLanguage,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存に失敗しました', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMissionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // タイトル
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '今日のミッション',
                style: AppTheme.headline2,
              ),
            ),
            // ミッションリスト
            Expanded(
              child: _todaysMissions.isEmpty
                ? Center(
                    child: Text(
                      'ミッションがありません',
                      style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _todaysMissions.length,
                    itemBuilder: (context, index) {
                      final mission = _todaysMissions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _MissionCard(mission: mission),
                      );
                    },
                  ),
            ),
            // 閉じるボタン
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getJapaneseTranslation(String englishText) {
    // 簡易的な翻訳例（実際のアプリではGemini APIなどを使用）
    if (englishText.contains('talked about')) {
      return '今日は${englishText.contains('hobbies') ? '趣味' : englishText.contains('work') ? '仕事' : englishText.contains('food') ? '食べ物' : '様々なこと'}について話しました。';
    } else if (englishText.contains('learned')) {
      return '新しい表現や単語を学びました。';
    } else if (englishText.contains('practiced')) {
      return '英会話の練習をしました。';
    }
    // デフォルト
    return '今日の会話では、楽しく英語の練習ができました。新しい表現を学び、自然な会話の流れを体験することができました。';
  }

  Widget _buildConversationSummaryCard() {
    final summary = widget.conversationSummary!['summary'] as String;
    final keyPhrases = widget.conversationSummary!['keyPhrases'] as List<String>? ?? [];
    final newWords = widget.conversationSummary!['newWords'] as List<String>? ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF5F5F5),
                        const Color(0xFFE8E8E8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🐿',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Acoとの会話まとめ',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // コンテンツ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 英語のまとめ
                Text(
                  summary,
                  style: AppTheme.body2.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // 日本語訳
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.translate,
                            size: 14,
                            color: AppTheme.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '日本語訳',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getJapaneseTranslation(summary),
                        style: AppTheme.caption.copyWith(
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (keyPhrases.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '使用した単語・熟語',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...keyPhrases.take(5).map((phrase) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.info.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          phrase,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                      ...newWords.take(5).map((word) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          word,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('変更を破棄しますか？', style: AppTheme.headline3),
        content: Text(
          '保存されていない変更があります。このページを離れますか？',
          style: AppTheme.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル', style: AppTheme.body2),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '破棄',
              style: AppTheme.body2.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundPrimary,
          elevation: 0,
          title: Text(
            widget.existingEntry != null ? '日記を編集' : '新しい日記',
            style: AppTheme.headline3,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.flag_outlined, color: AppTheme.primaryColor),
              onPressed: _showMissionsModal,
              tooltip: '今日のミッション',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル入力
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _titleFocusNode.hasFocus 
                              ? AppTheme.primaryBlue.withOpacity(0.3)
                              : AppTheme.borderColor.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          decoration: InputDecoration(
                            hintText: '日記のタイトルを入力',
                            hintStyle: AppTheme.body2.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: AppTheme.headline3,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _contentFocusNode.requestFocus(),
                        ),
                      ),
                      
                      // リアルタイム翻訳を削除
                      /*if (_translatedTitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.translate,
                                size: 16,
                                color: AppTheme.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _translatedTitle,
                                  style: AppTheme.body2.copyWith(
                                    color: AppTheme.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],*/
                      
                      const SizedBox(height: 20),
                      
                      // 内容入力
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _contentFocusNode.hasFocus 
                              ? AppTheme.primaryBlue.withOpacity(0.3)
                              : AppTheme.borderColor.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          decoration: InputDecoration(
                            hintText: _detectedLanguage == 'ja' 
                              ? '今日の出来事や感想を書いてみましょう'
                              : 'Write about your day and thoughts',
                            hintStyle: AppTheme.body2.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: AppTheme.body1,
                          maxLines: 10,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 会話のまとめまたはAcoと会話ボタン
                      if (widget.conversationSummary != null) 
                        _buildConversationSummaryCard()
                      else
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConversationJournalScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.1),
                                  AppTheme.primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF5F5F5),
                                        const Color(0xFFE8E8E8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '🐿',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '日記のネタを見つける',
                                        style: AppTheme.body1.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Acoとの会話から今日の出来事を振り返りましょう',
                                        style: AppTheme.body2.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // リアルタイム翻訳を削除
                      /*if (_translatedContent.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AppCard(
                          backgroundColor: AppTheme.backgroundTertiary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.translate,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '翻訳',
                                    style: AppTheme.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_detectedLanguage.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _detectedLanguage == 'ja' ? '日本語 → 英語' : 'English → 日本語',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTranslatedText(_translatedContent),
                            ],
                          ),
                        ),
                      ],*/
                      
                      if (_selectedWords.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AppCard(
                          backgroundColor: AppTheme.success.withOpacity(0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.bookmark,
                                    size: 18,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '登録した単語 (${_selectedWords.length})',
                                    style: AppTheme.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedWords.map((word) {
                                  return Chip(
                                    label: Text(
                                      '${word.english} - ${word.japanese}',
                                      style: AppTheme.caption,
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedWords.remove(word);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // 保存ボタン
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPrimary,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: PrimaryButton(
                  text: widget.existingEntry != null ? '更新する' : '保存する',
                  onPressed: _saveDiary,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslatedText(String text) {
    final words = text.split(' ');
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      
      // 単語の翻訳候補を取得
      final suggestions = TranslationService.suggestTranslations(cleanWord);
      final hasTranslation = suggestions.isNotEmpty;
      
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
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: hasTranslation
                    ? Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Text(
                word,
                style: AppTheme.body1.copyWith(
                  color: hasTranslation ? AppTheme.primaryBlue : AppTheme.textPrimary,
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
                  final word = Word(
                    id: const Uuid().v4(),
                    english: english,
                    japanese: japanese,
                    createdAt: DateTime.now(),
                  );
                  
                  setState(() {
                    _selectedWords.add(word);
                  });
                  
                  Navigator.pop(context);
                  
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
}

// ミッションカードWidget（ホーム画面のデザインを流用）
class _MissionCard extends StatelessWidget {
  final Mission mission;

  const _MissionCard({
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final bool completed = mission.isCompleted;
    final IconData icon = _getIconFromType(mission.type);
    final Color color = _getColorFromType(mission.type);
    
    return AppCard(
      onTap: null, // タップ不可
      backgroundColor: completed ? AppTheme.backgroundTertiary : AppTheme.backgroundPrimary,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completed
                ? AppTheme.textTertiary.withOpacity(0.1)
                : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : icon,
              color: completed ? AppTheme.textTertiary : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed ? AppTheme.textTertiary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: AppTheme.caption.copyWith(
                    color: completed ? AppTheme.textTertiary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: mission.targetValue > 0
                    ? (mission.currentValue / mission.targetValue).clamp(0.0, 1.0)
                    : 0.0,
                  backgroundColor: AppTheme.backgroundTertiary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed ? AppTheme.textTertiary : color,
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mission.currentValue}/${mission.targetValue}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (completed)
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppTheme.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromType(MissionType type) {
    switch (type) {
      case MissionType.dailyDiary:
        return Icons.edit_note;
      case MissionType.wordLearning:
        return Icons.book;
      case MissionType.conversation:
        return Icons.chat_bubble_outline;
      case MissionType.streak:
        return Icons.local_fire_department;
      case MissionType.review:
        return Icons.refresh;
    }
  }

  Color _getColorFromType(MissionType type) {
    switch (type) {
      case MissionType.dailyDiary:
        return AppTheme.primaryBlue;
      case MissionType.wordLearning:
        return AppTheme.success;
      case MissionType.conversation:
        return AppTheme.secondaryColor;
      case MissionType.streak:
        return AppTheme.warning;
      case MissionType.review:
        return AppTheme.success;
    }
  }
}