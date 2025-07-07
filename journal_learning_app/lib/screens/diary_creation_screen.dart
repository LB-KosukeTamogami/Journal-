import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';

class DiaryCreationScreen extends StatefulWidget {
  final DiaryEntry? existingEntry;

  const DiaryCreationScreen({
    Key? key,
    this.existingEntry,
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
  bool _isTranslating = false;
  String _translatedContent = '';
  Map<String, String> _wordSuggestions = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title;
      _contentController.text = widget.existingEntry!.content;
    }
    
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _contentController.addListener(_updateWordSuggestions);
  }

  void _updateWordSuggestions() {
    final text = _contentController.text;
    if (text.isNotEmpty) {
      setState(() {
        _wordSuggestions = TranslationService.suggestTranslations(text);
      });
    }
  }

  Future<void> _translateContent() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showSnackBar('翻訳するテキストを入力してください', isError: true);
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final sourceLanguage = TranslationService.detectLanguage(content);
      final targetLanguage = sourceLanguage == 'ja' ? 'en' : 'ja';
      
      final result = await TranslationService.translate(
        content,
        targetLanguage: targetLanguage,
      );

      if (result.success) {
        setState(() {
          _translatedContent = result.translatedText;
        });
        
        _showTranslationDialog(result);
      } else {
        _showSnackBar(result.error ?? '翻訳に失敗しました', isError: true);
      }
    } catch (e) {
      _showSnackBar('翻訳中にエラーが発生しました', isError: true);
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _showTranslationDialog(TranslationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '翻訳結果',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '元のテキスト:',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.originalText,
              style: GoogleFonts.notoSans(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              '翻訳:',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.translatedText,
              style: GoogleFonts.notoSans(fontSize: 14),
            ),
            if (result.isPartialTranslation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '※ 部分的な翻訳です',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '閉じる',
              style: GoogleFonts.notoSans(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 翻訳結果をクリップボードにコピー（将来実装）
              _showSnackBar('翻訳結果をコピーしました', isError: false);
            },
            child: Text(
              'コピー',
              style: GoogleFonts.notoSans(
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
        createdAt: widget.existingEntry?.createdAt ?? now,
        updatedAt: now,
        wordCount: _contentController.text.trim().split(' ').length,
        isCompleted: true,
      );

      await StorageService.saveDiaryEntry(entry);

      if (mounted) {
        Navigator.pop(context, entry);
        _showSnackBar(
          widget.existingEntry != null ? '日記を更新しました' : '日記を作成しました',
          isError: false,
        );
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
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '変更を破棄しますか？',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '保存されていない変更があります。このページを離れますか？',
          style: GoogleFonts.notoSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'キャンセル',
              style: GoogleFonts.notoSans(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '破棄',
              style: GoogleFonts.notoSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.existingEntry != null ? '日記を編集' : '新しい日記',
            style: GoogleFonts.notoSans(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: _isTranslating ? null : _translateContent,
              icon: _isTranslating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : const Icon(Icons.translate, color: Color(0xFF6366F1)),
              tooltip: '翻訳',
            ),
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveDiary,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      )
                    : Text(
                        '保存',
                        style: GoogleFonts.notoSans(
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: InputDecoration(
                      hintText: '日記のタイトルを入力...',
                      hintStyle: GoogleFonts.notoSans(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contentFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      decoration: InputDecoration(
                        hintText: '今日の出来事や感想を英語で書いてみましょう...',
                        hintStyle: GoogleFonts.notoSans(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: Colors.black,
                        height: 1.6,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_wordSuggestions.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, 
                                 color: Colors.blue[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '単語の翻訳候補',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _wordSuggestions.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${entry.key} → ${entry.value}',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDiary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.existingEntry != null ? '更新する' : '保存する',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}