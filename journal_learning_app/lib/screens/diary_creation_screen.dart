import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/mission_service.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import 'diary_review_screen.dart';

class DiaryCreationScreen extends StatefulWidget {
  final DiaryEntry? existingEntry;
  final String? initialContent;

  const DiaryCreationScreen({
    Key? key,
    this.existingEntry,
    this.initialContent,
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
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDiary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '保存',
                          style: AppTheme.button.copyWith(fontSize: 14),
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
                            hintText: '日記のタイトルを入力...',
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
                              ? '今日の出来事や感想を書いてみましょう...'
                              : 'Write about your day and thoughts...',
                            hintStyle: AppTheme.body2.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: AppTheme.body1,
                          maxLines: 10,
                          textInputAction: TextInputAction.newline,
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