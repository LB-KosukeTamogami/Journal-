import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import '../widgets/text_to_speech_button.dart';
import '../widgets/japanese_dictionary_dialog.dart';
import 'flashcard_session_screen.dart' hide AppCard;

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Word> _allWords = [];
  bool _isLoading = true;
  Set<int> _selectedMasteryLevels = {0, 1}; // Default: show × and △ only
  
  // フィルター関連の状態
  Set<WordCategory> _selectedCategories = WordCategory.values.toSet();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final words = await StorageService.getWords();
      setState(() {
        _allWords = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('学習', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.filter_list,
                  color: _hasActiveFilters() ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                Container(
                  color: AppTheme.backgroundPrimary,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: AppTheme.body2,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Container(
                            width: double.infinity,
                            child: const Center(child: Text('すべて')),
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: double.infinity,
                            child: const Center(child: Text('学習中')),
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: double.infinity,
                            child: const Center(child: Text('習得済み')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCardList(_getFilteredWords(_allWords)),
                      _buildLearningTab(),
                      _buildCardList(_getFilteredWords(_allWords.where((word) => word.masteryLevel == 2).toList())),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.buttonShadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            _startFlashcardSession();
          },
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: Text('学習を開始', style: AppTheme.button),
        ),
      ),
    );
  }

  Widget _buildLearningTab() {
    final learningWords = _getFilteredWords(_allWords).where((word) => word.masteryLevel < 2).toList();
    final filteredWords = learningWords.where((word) => 
      _selectedMasteryLevels.contains(word.masteryLevel)
    ).toList();

    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '絞り込み:',
                style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: '×',
                      value: 0,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '△',
                      value: 1,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCardList(filteredWords),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int value,
    required Color color,
  }) {
    final isSelected = _selectedMasteryLevels.contains(value);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMasteryLevels.remove(value);
          } else {
            _selectedMasteryLevels.add(value);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body1.copyWith(
            color: isSelected ? color : AppTheme.textTertiary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCardList(List<Word> words) {
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'カードがありません',
              style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '日記を書いて単語を登録しましょう',
              style: AppTheme.body2.copyWith(color: AppTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _FlashcardItem(
          word: word,
          onTap: () => _showCardDetail(word),
          onToggleLearned: () async {
            // Toggle between mastered (2) and not mastered (0)
            final newLevel = word.masteryLevel == 2 ? 0 : 2;
            await StorageService.updateWordReview(word.id, masteryLevel: newLevel);
            _loadWords();
          },
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 50),
          duration: 300.ms,
        ).slideX(begin: 0.1, end: 0);
      },
    );
  }

  void _showCardDetail(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word.english,
                  style: AppTheme.headline2,
                ),
                TextToSpeechButton(
                  text: word.english,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              word.japanese,
              style: AppTheme.body1.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppTheme.backgroundTertiary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '例文',
                        style: AppTheme.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (word.example != null) ...[
                    Text(
                      word.example!,
                      style: AppTheme.body1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '例文',
                      style: AppTheme.body2,
                    ),
                  ] else
                    Text(
                      '例文なし',
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      JapaneseDictionaryDialog.show(context, word.english);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book, size: 20),
                    label: const Text('辞書'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Toggle between mastered (2) and not mastered (0)
                      final newLevel = word.masteryLevel == 2 ? 0 : 2;
                      await StorageService.updateWordReview(word.id, masteryLevel: newLevel);
                      Navigator.pop(context);
                      _loadWords();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: word.isMastered 
                          ? AppTheme.warning
                          : AppTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      word.isMastered ? Icons.close : Icons.check,
                      size: 20,
                    ),
                    label: Text(
                      word.isMastered ? '未習得に戻す' : '習得済みにする',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 削除ボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteWord(word);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                label: Text(
                  '削除',
                  style: AppTheme.body2.copyWith(color: AppTheme.error),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _deleteWord(Word word) {
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
          '「${word.english}」を削除しますか？',
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
            onPressed: () async {
              await StorageService.deleteWord(word.id);
              Navigator.pop(context);
              _loadWords();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '削除しました',
                    style: AppTheme.body2.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.textSecondary,
                ),
              );
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

  bool _hasActiveFilters() {
    // カテゴリフィルターがすべて選択されていない、または日付フィルターが設定されている場合
    return _selectedCategories.length != WordCategory.values.length ||
           _startDate != null ||
           _endDate != null;
  }

  List<Word> _getFilteredWords(List<Word> words) {
    return words.where((word) {
      // カテゴリフィルター
      if (!_selectedCategories.contains(word.category)) {
        return false;
      }
      
      // 日付フィルター
      if (_startDate != null && word.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && word.createdAt.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'フィルター',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 24),
                    
                    // カテゴリフィルター
                    Text(
                      'カテゴリ',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WordCategory.values.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedCategories.remove(category);
                              } else {
                                _selectedCategories.add(category);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              category.displayName,
                              style: AppTheme.body2.copyWith(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 日付範囲フィルター
                    Text(
                      '登録日',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppTheme.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setModalState(() {
                                  _startDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startDate != null
                                        ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                                        : '開始日',
                                    style: AppTheme.body2.copyWith(
                                      color: _startDate != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('〜', style: AppTheme.body2),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppTheme.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setModalState(() {
                                  _endDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endDate != null
                                        ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                                        : '終了日',
                                    style: AppTheme.body2.copyWith(
                                      color: _endDate != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ボタン
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategories = WordCategory.values.toSet();
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              'リセット',
                              style: AppTheme.body1.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '適用',
                              style: AppTheme.button,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startFlashcardSession() {
    // Get words based on current tab and filters
    List<Word> sessionWords;
    
    if (_tabController.index == 1) {
      // Learning tab with filters
      final learningWords = _getFilteredWords(_allWords).where((word) => word.masteryLevel < 2).toList();
      sessionWords = learningWords.where((word) => 
        _selectedMasteryLevels.contains(word.masteryLevel)
      ).toList();
    } else if (_tabController.index == 2) {
      // Mastered tab
      sessionWords = _getFilteredWords(_allWords).where((word) => word.masteryLevel == 2).toList();
    } else {
      // All tab
      sessionWords = _getFilteredWords(_allWords);
    }
    
    if (sessionWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('学習するカードがありません', style: AppTheme.body2.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.textSecondary,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSessionScreen(words: sessionWords),
      ),
    ).then((_) => _loadWords());
  }
}

class _FlashcardItem extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;
  final VoidCallback onToggleLearned;

  const _FlashcardItem({
    required this.word,
    required this.onTap,
    required this.onToggleLearned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  word.english[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        word.english,
                        style: AppTheme.body1.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (word.masteryLevel == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (word.masteryLevel == 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '△',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (word.masteryLevel == 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '○',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.japanese,
                    style: AppTheme.body2,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleLearned,
              icon: Icon(
                word.isMastered ? Icons.check_circle : Icons.circle_outlined,
                color: word.isMastered ? AppTheme.success : AppTheme.textTertiary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

}