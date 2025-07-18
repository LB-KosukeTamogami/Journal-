import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
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
  bool _showNew = true; // NEW表示フラグ
  bool _showFailed = true; // ×表示フラグ
  
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
  
  Future<void> _removeDuplicates() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await StorageService.removeDuplicateWords();
      await _loadWords();
      
      if (mounted) {
        Navigator.pop(context); // ローディングを閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('重複した単語を削除しました'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ローディングを閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: (value) async {
              if (value == 'remove_duplicates') {
                await _removeDuplicates();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'remove_duplicates',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('重複を削除'),
                  ],
                ),
              ),
            ],
          ),
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
    
    // 新しいフィルタリングロジック
    final filteredWords = learningWords.where((word) {
      if (word.masteryLevel == 0) {
        // NEWステータス（reviewCount = 0 かつ lastReviewedAt = null）と×ステータスを区別
        final isNewStatus = word.reviewCount == 0 && word.lastReviewedAt == null;
        if (isNewStatus) {
          return _showNew; // NEWフィルターでのみ表示
        } else {
          return _showFailed; // ×フィルターでのみ表示
        }
      } else {
        // masteryLevel 1の場合、△のフラグをチェック
        return _selectedMasteryLevels.contains(word.masteryLevel);
      }
    }).toList();

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
                    _buildNewFilterChip(),
                    const SizedBox(width: 8),
                    _buildFailedFilterChip(),
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

  Widget _buildNewFilterChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showNew = !_showNew;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _showNew ? AppTheme.primaryBlue.withOpacity(0.15) : AppTheme.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showNew ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: _showNew ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.new_releases,
              size: 16,
              color: _showNew ? AppTheme.primaryBlue : AppTheme.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'NEW',
              style: AppTheme.body1.copyWith(
                color: _showNew ? AppTheme.primaryBlue : AppTheme.textTertiary,
                fontWeight: _showNew ? FontWeight.w600 : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedFilterChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFailed = !_showFailed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _showFailed ? AppTheme.error.withOpacity(0.15) : AppTheme.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showFailed ? AppTheme.error : AppTheme.borderColor,
            width: _showFailed ? 2 : 1,
          ),
        ),
        child: Text(
          '×',
          style: AppTheme.body1.copyWith(
            color: _showFailed ? AppTheme.error : AppTheme.textTertiary,
            fontWeight: _showFailed ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildIconFilterChip({
    required IconData icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : AppTheme.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.body1.copyWith(
                color: isSelected ? color : AppTheme.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
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
      builder: (context) => _WordDetailModal(
        word: word,
        onUpdate: () {
          _loadWords();
        },
      ),
    );
  }

  Widget _buildStatusButton({
    required int currentLevel,
    required int targetLevel,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentLevel == targetLevel;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.body1.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label == '×' ? '未学習' :
                label == '△' ? '学習中' : '習得済み',
                style: AppTheme.caption.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
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
    // モーダル用の一時的な状態変数
    Set<WordCategory> tempSelectedCategories = Set.from(_selectedCategories);
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
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
                        final isSelected = tempSelectedCategories.contains(category);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelectedCategories.remove(category);
                              } else {
                                tempSelectedCategories.add(category);
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
                                initialDate: tempStartDate ?? DateTime.now(),
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
                                  tempStartDate = date;
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
                                    tempStartDate != null
                                        ? '${tempStartDate!.year}/${tempStartDate!.month}/${tempStartDate!.day}'
                                        : '開始日',
                                    style: AppTheme.body2.copyWith(
                                      color: tempStartDate != null
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
                                initialDate: tempEndDate ?? DateTime.now(),
                                firstDate: tempStartDate ?? DateTime(2020),
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
                                  tempEndDate = date;
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
                                    tempEndDate != null
                                        ? '${tempEndDate!.year}/${tempEndDate!.month}/${tempEndDate!.day}'
                                        : '終了日',
                                    style: AppTheme.body2.copyWith(
                                      color: tempEndDate != null
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
                                tempSelectedCategories = WordCategory.values.toSet();
                                tempStartDate = null;
                                tempEndDate = null;
                              });
                            },
                            style: AppButtonStyles.secondaryButton.copyWith(
                              foregroundColor: MaterialStateProperty.all(AppTheme.textSecondary),
                              side: MaterialStateProperty.all(
                                BorderSide(color: AppTheme.borderColor, width: 1),
                              ),
                            ),
                            child: const Text('リセット'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategories = tempSelectedCategories;
                                _startDate = tempStartDate;
                                _endDate = tempEndDate;
                              });
                              Navigator.pop(context);
                            },
                            style: AppButtonStyles.primaryButton,
                            child: const Text('適用'),
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
      sessionWords = learningWords.where((word) {
        if (word.masteryLevel == 0) {
          final isNewStatus = word.reviewCount == 0 && word.lastReviewedAt == null;
          if (isNewStatus) {
            return _showNew;
          } else {
            return _showFailed;
          }
        } else {
          return _selectedMasteryLevels.contains(word.masteryLevel);
        }
      }).toList();
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          word.english,
                          style: AppTheme.body1.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (word.reviewCount == 0 && word.lastReviewedAt == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.new_releases,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'NEW',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (word.masteryLevel == 0 && (word.reviewCount > 0 || word.lastReviewedAt != null))
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

class _WordDetailModal extends StatefulWidget {
  final Word word;
  final VoidCallback onUpdate;

  const _WordDetailModal({
    required this.word,
    required this.onUpdate,
  });

  @override
  State<_WordDetailModal> createState() => _WordDetailModalState();
}

class _WordDetailModalState extends State<_WordDetailModal> {
  bool _isAddedToVocabulary = false;

  @override
  Widget build(BuildContext context) {
    // NEWステータスかどうかを判定（reviewCount = 0 かつ lastReviewedAt = null）
    final isNewStatus = widget.word.reviewCount == 0 && widget.word.lastReviewedAt == null;
    
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
      child: SingleChildScrollView(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word.english,
                        style: AppTheme.headline2,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.word.japanese,
                        style: AppTheme.body1.copyWith(fontSize: 18),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                    _getPartOfSpeech(widget.word.english),
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextToSpeechButton(
                  text: widget.word.english,
                ),
              ],
            ),
            
            
            const SizedBox(height: 20),
            // ステータス変更セクション
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ステータス',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusButton(
                      currentLevel: isNewStatus ? -1 : widget.word.masteryLevel, // NEWの場合は-1を渡して何も選択されていない状態に
                      targetLevel: 0,
                      icon: Icons.close,
                      label: '×',
                      color: AppTheme.error,
                      onTap: () async {
                        await StorageService.updateWordReview(widget.word.id, masteryLevel: 0);
                        Navigator.pop(context);
                        widget.onUpdate();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      currentLevel: isNewStatus ? -1 : widget.word.masteryLevel, // NEWの場合は-1を渡して何も選択されていない状態に
                      targetLevel: 1,
                      icon: Icons.change_history,
                      label: '△',
                      color: AppTheme.warning,
                      onTap: () async {
                        await StorageService.updateWordReview(widget.word.id, masteryLevel: 1);
                        Navigator.pop(context);
                        widget.onUpdate();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildStatusButton(
                      currentLevel: isNewStatus ? -1 : widget.word.masteryLevel, // NEWの場合は-1を渡して何も選択されていない状態に
                      targetLevel: 2,
                      icon: Icons.circle,
                      label: '○',
                      color: AppTheme.success,
                      onTap: () async {
                        await StorageService.updateWordReview(widget.word.id, masteryLevel: 2);
                        Navigator.pop(context);
                        widget.onUpdate();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 単語帳に登録ボタン
            AppButtonStyles.withShadow(
              ElevatedButton.icon(
                onPressed: () async {
                  // フラッシュカードに登録/削除のトグル
                  try {
                    if (_isAddedToVocabulary) {
                      // 既に追加済みの場合は削除
                      final flashcards = await StorageService.getFlashcards();
                      final cardToDelete = flashcards.firstWhere(
                        (card) => card.word.toLowerCase() == widget.word.english.toLowerCase(),
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
                        setState(() {
                          _isAddedToVocabulary = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('単語帳から削除しました'),
                            backgroundColor: AppTheme.warning,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
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
                        word: widget.word.english,
                        meaning: widget.word.japanese,
                        exampleSentence: '', // 例文は削除
                        createdAt: DateTime.now(),
                        lastReviewed: DateTime.now(),
                        nextReviewDate: DateTime.now().add(Duration(days: 1)),
                        reviewCount: 0,
                      );
                      await StorageService.saveFlashcard(flashcard);
                      
                      setState(() {
                        _isAddedToVocabulary = true;
                      });
                      
                      // 成功メッセージを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('単語帳に登録しました'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
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
                style: _isAddedToVocabulary
                  ? AppButtonStyles.modalErrorButton
                  : AppButtonStyles.modalSuccessButton,
                icon: Icon(
                  _isAddedToVocabulary ? Icons.check_circle : Icons.style,
                  size: 20,
                  color: _isAddedToVocabulary ? AppTheme.error : Colors.white,
                ),
                label: Text(
                  _isAddedToVocabulary ? '単語帳に登録済み' : '単語帳に登録',
                  style: TextStyle(
                    color: _isAddedToVocabulary ? AppTheme.error : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 削除ボタン
            AppButtonStyles.withShadow(
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteWord(widget.word);
                },
                style: AppButtonStyles.modalErrorButton,
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

  Widget _buildStatusButton({
    required int currentLevel,
    required int targetLevel,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentLevel == targetLevel;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.body1.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label == '×' ? '未学習' :
                label == '△' ? '学習中' : '習得済み',
                style: AppTheme.caption.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
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
              widget.onUpdate();
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