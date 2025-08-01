import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';
import '../widgets/text_to_speech_button.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    try {
      final flashcards = await StorageService.getFlashcards();
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Flashcard> _getFilteredFlashcards() {
    if (_searchQuery.isEmpty) {
      return _flashcards;
    }
    
    return _flashcards.where((flashcard) {
      return flashcard.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             flashcard.meaning.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    try {
      await StorageService.deleteFlashcard(flashcard.id);
      _loadFlashcards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${flashcard.word}」を削除しました'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('削除に失敗しました'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '削除の確認',
          style: AppTheme.headline3,
        ),
        content: Text(
          '「${flashcard.word}」を単語帳から削除しますか？',
          style: AppTheme.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFlashcard(flashcard);
            },
            child: Text(
              '削除',
              style: AppTheme.body1.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('単語帳', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 検索バー
          Container(
            color: AppTheme.backgroundPrimary,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '単語を検索...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // 単語帳の統計
          if (!_isLoading) _buildStatsSection(),
          
          // 単語リスト
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _buildFlashcardsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final filteredCards = _getFilteredFlashcards();
    final totalCards = filteredCards.length;
    
    return Container(
      color: AppTheme.backgroundPrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.book,
              label: '総単語数',
              value: totalCards.toString(),
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule,
              label: '最近追加',
              value: _getRecentlyAddedCount().toString(),
              color: AppTheme.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headline2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  int _getRecentlyAddedCount() {
    final now = DateTime.now();
    final recentThreshold = now.subtract(const Duration(days: 7));
    
    return _flashcards.where((card) => card.createdAt.isAfter(recentThreshold)).length;
  }

  Widget _buildFlashcardsList() {
    final filteredCards = _getFilteredFlashcards();
    
    if (filteredCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.book_outlined : Icons.search_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '単語帳が空です' : '検索結果が見つかりません',
              style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? '日記を書いて単語を登録しましょう' 
                  : '別のキーワードで検索してみてください',
              style: AppTheme.body2.copyWith(color: AppTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        final flashcard = filteredCards[index];
        return _buildFlashcardItem(flashcard, index);
      },
    );
  }

  Widget _buildFlashcardItem(Flashcard flashcard, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 単語のアイコン
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          flashcard.word[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 単語と意味
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flashcard.word,
                            style: AppTheme.body1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            flashcard.meaning,
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 音声ボタン
                    TextToSpeechButton(
                      text: flashcard.word,
                    ),
                    
                    // 削除ボタン
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(flashcard),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                // 追加日時
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '追加日: ${_formatDate(flashcard.createdAt)}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: index * 50),
      duration: 300.ms,
    ).slideX(begin: 0.1, end: 0);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}