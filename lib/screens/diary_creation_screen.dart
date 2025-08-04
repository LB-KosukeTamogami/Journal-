import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/diary_entry.dart';
import '../models/mission.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/mission_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'diary_review_screen.dart';
import 'conversation_journal_screen.dart';
import 'main_navigation_screen.dart';

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
        isCompleted: false,
        learnedWords: [],
      );

      print('[DiaryCreation] Saving diary entry...');
      await StorageService.saveDiaryEntry(entry);
      print('[DiaryCreation] Diary saved successfully');
      
      // ミッション更新
      await MissionService.updateMissionProgress(MissionType.dailyDiary);
      
      if (!mounted) return;

      // レビュー画面へ遷移
      // Detect language for the review screen
      final detectedLang = TranslationService.detectLanguage(entry.content);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryReviewScreen(
            entry: entry,
            detectedLanguage: detectedLang,
          ),
        ),
      );
    } catch (e) {
      print('[DiaryCreation] Error saving diary: $e');
      _showSnackBar('保存に失敗しました: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('変更を破棄しますか？'),
        content: const Text('保存されていない変更があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('破棄する'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildConversationSummaryCard() {
    if (widget.conversationSummary == null) return const SizedBox.shrink();

    final summary = widget.conversationSummary!;
    final extractedWords = summary['newWords'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '会話から作成',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          if (extractedWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '抽出された単語',
              style: AppTheme.body2.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: extractedWords.map((word) {
                return GestureDetector(
                  onTap: () => _showWordDetail(word.toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      word.toString(),
                      style: AppTheme.caption.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showWordDetail(String word) async {
    // TODO: 単語の詳細を表示する機能を実装
    _showSnackBar('単語の詳細機能は開発中です', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.existingEntry != null ? '日記を編集' : '日記を書く',
            style: AppTheme.heading1,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveDiary,
                child: Text(
                  '保存',
                  style: AppTheme.body1.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 会話サマリーカード
                      _buildConversationSummaryCard(),
                      
                      // タイトル入力
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: AppTheme.heading1,
                        decoration: InputDecoration(
                          hintText: 'タイトルを入力',
                          hintStyle: AppTheme.heading1.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _contentFocusNode.requestFocus();
                        },
                      ),
                      
                      Divider(
                        color: Theme.of(context).dividerColor,
                        height: 1,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 言語検出表示
                      if (_detectedLanguage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _detectedLanguage == 'ja' ? '日本語' : '英語',
                                style: AppTheme.caption.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // 内容入力
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        style: AppTheme.body1.copyWith(height: 1.8),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: '今日の出来事を書いてみましょう...',
                          hintStyle: AppTheme.body1.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.newline,
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              
              // 下部のアクションバー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // 文字数カウント
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_contentController.text.split(' ').where((word) => word.isNotEmpty).length} words',
                              style: AppTheme.caption.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // 会話で作成ボタン
                      if (widget.existingEntry == null && widget.conversationSummary == null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConversationJournalScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          label: Text(
                            '会話で作成',
                            style: AppTheme.body2.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}