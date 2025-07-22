import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../widgets/text_to_speech_button.dart';
import '../widgets/japanese_dictionary_dialog.dart';
import 'word_study_session_screen.dart' hide AppCard;

// 並べ替えの種類
enum SortOrder { dateAsc, dateDesc, alphabetAsc, alphabetDesc }

class LearningScreen extends StatefulWidget {
  final WordCategory? initialCategory;
  
  const LearningScreen({
    super.key,
    this.initialCategory,
  });

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
  
  // 並べ替え関連の状態
  SortOrder _sortOrder = SortOrder.dateDesc; // デフォルトは追加日の降順

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 初期カテゴリが指定されている場合はそれだけを選択、なければ全て選択
    if (widget.initialCategory != null) {
      _selectedCategories = {widget.initialCategory!};
    } else {
      _selectedCategories = WordCategory.values.toSet();
    }
    
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

  String _getHeaderTitle() {
    if (widget.initialCategory != null) {
      return widget.initialCategory!.displayName;
    } else {
      return 'すべて';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text(_getHeaderTitle(), style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: (value) async {
              if (value == 'remove_duplicates') {
                await _removeDuplicates();
              } else if (value == 'update_categories') {
                await _updateWordCategories();
              } else if (value == 'remove_unwanted_words') {
                await _removeUnwantedWords();
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
              const PopupMenuItem<String>(
                value: 'update_categories',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('品詞を更新'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'remove_unwanted_words',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20),
                    SizedBox(width: 8),
                    Text('不要な語句を削除'),
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
                      labelPadding: const EdgeInsets.symmetric(vertical: 4),
                      tabs: [
                        Tab(
                          child: _buildTabContent(
                            'すべて',
                            '${_getFilteredWords(_allWords).length}個',
                            0,
                          ),
                        ),
                        Tab(
                          child: _buildTabContent(
                            '学習中',
                            '${_getFilteredWords(_allWords).where((word) => word.masteryLevel < 2).length}個',
                            1,
                          ),
                        ),
                        Tab(
                          child: _buildTabContent(
                            '習得済み',
                            '${_getFilteredWords(_allWords).where((word) => word.masteryLevel == 2).length}個',
                            2,
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
            _startWordStudySession();
          },
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: Text('学習を開始', style: AppTheme.button),
        ),
      ),
    );
  }

  Widget _buildTabContent(String title, String count, int index) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        return Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: AppTheme.caption.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
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
        return _WordCardItem(
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
    // 初期カテゴリが指定されている場合は、日付フィルターのみをチェック
    if (widget.initialCategory != null) {
      return _startDate != null || _endDate != null;
    }
    // 初期カテゴリが指定されていない場合は、従来通りの判定
    return _selectedCategories.length != WordCategory.values.length ||
           _startDate != null ||
           _endDate != null;
  }

  List<Word> _getFilteredWords(List<Word> words) {
    final filtered = words.where((word) {
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
    
    // 並べ替え
    switch (_sortOrder) {
      case SortOrder.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.alphabetAsc:
        filtered.sort((a, b) => a.english.toLowerCase().compareTo(b.english.toLowerCase()));
        break;
      case SortOrder.alphabetDesc:
        filtered.sort((a, b) => b.english.toLowerCase().compareTo(a.english.toLowerCase()));
        break;
    }
    
    return filtered;
  }

  void _showFilterBottomSheet() {
    // モーダル用の一時的な状態変数
    Set<WordCategory> tempSelectedCategories = Set.from(_selectedCategories);
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    SortOrder tempSortOrder = _sortOrder;
    
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
                    
                    // カテゴリフィルター（初期カテゴリが指定されていない場合のみ表示）
                    if (widget.initialCategory == null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'カテゴリ',
                            style: AppTheme.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              if (tempSelectedCategories.length == WordCategory.values.length) {
                                // すべて選択されている場合は解除
                                tempSelectedCategories.clear();
                              } else {
                                // 一部またはすべて解除されている場合は全選択
                                tempSelectedCategories = WordCategory.values.toSet();
                              }
                            });
                          },
                          child: Text(
                            tempSelectedCategories.length == WordCategory.values.length 
                                ? 'すべて解除' 
                                : 'すべて選択',
                            style: AppTheme.caption.copyWith(
                              color: tempSelectedCategories.length == WordCategory.values.length
                                  ? AppTheme.textSecondary
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // グリッドレイアウトで固定配置
                    SizedBox(
                      height: 140, // 3行分の高さを調整
                      child: GridView.count(
                        crossAxisCount: 4, // 4列固定
                        childAspectRatio: 2.0, // ボタンの横幅と高さの比率
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(), // スクロール無効
                        shrinkWrap: true,
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
                              child: Center(
                                child: Text(
                                  category.displayName,
                                  style: AppTheme.body2.copyWith(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    ],
                    
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
                              final selectedRange = await _showDateRangePicker(context, tempStartDate, tempEndDate);
                              if (selectedRange != null) {
                                setModalState(() {
                                  tempStartDate = selectedRange['start'];
                                  tempEndDate = selectedRange['end'];
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
                              final selectedRange = await _showDateRangePicker(context, tempStartDate, tempEndDate);
                              if (selectedRange != null) {
                                setModalState(() {
                                  tempStartDate = selectedRange['start'];
                                  tempEndDate = selectedRange['end'];
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
                    
                    const SizedBox(height: 16),
                    
                    // 並べ替え
                    Text(
                      '並べ替え',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '追加日',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile<SortOrder>(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  title: Text('新しい順', style: AppTheme.body2),
                                  value: SortOrder.dateDesc,
                                  groupValue: tempSortOrder,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() {
                                        tempSortOrder = value;
                                      });
                                    }
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<SortOrder>(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  title: Text('古い順', style: AppTheme.body2),
                                  value: SortOrder.dateAsc,
                                  groupValue: tempSortOrder,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() {
                                        tempSortOrder = value;
                                      });
                                    }
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            'アルファベット',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile<SortOrder>(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  title: Text('A-Z', style: AppTheme.body2),
                                  value: SortOrder.alphabetAsc,
                                  groupValue: tempSortOrder,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() {
                                        tempSortOrder = value;
                                      });
                                    }
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<SortOrder>(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  title: Text('Z-A', style: AppTheme.body2),
                                  value: SortOrder.alphabetDesc,
                                  groupValue: tempSortOrder,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() {
                                        tempSortOrder = value;
                                      });
                                    }
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
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
                                tempSortOrder = SortOrder.dateDesc;
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
                                _sortOrder = tempSortOrder;
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

  Future<void> _updateWordCategories() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final words = await StorageService.getWords();
      int updatedCount = 0;
      
      for (final word in words) {
        // 既にother以外のカテゴリが設定されている場合はスキップ
        if (word.category != WordCategory.other) {
          continue;
        }
        
        // 品詞を判定
        final category = _getWordCategory(word.english);
        
        // カテゴリが変わる場合のみ更新
        if (category != word.category) {
          final updatedWord = word.copyWith(category: category);
          await StorageService.saveWord(updatedWord);
          updatedCount++;
        }
      }
      
      
      // リロード
      await _loadWords();
      
      if (mounted) {
        Navigator.pop(context); // ローディングを閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$updatedCount個の単語の品詞を更新しました',
              style: AppTheme.body2.copyWith(color: Colors.white),
            ),
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
  
  Future<void> _removeUnwantedWords() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final words = await StorageService.getWords();
      int deletedCount = 0;
      
      // 不要な語句のリスト
      final unwantedWords = ['it was', 'it is', 'there was', 'there is', 'there are', 'there were'];
      
      for (final word in words) {
        if (unwantedWords.contains(word.english.toLowerCase())) {
          await StorageService.deleteWord(word.id);
          deletedCount++;
        }
      }
      
      
      // リロード
      await _loadWords();
      
      if (mounted) {
        Navigator.pop(context); // ローディングを閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$deletedCount個の不要な語句を削除しました',
              style: AppTheme.body2.copyWith(color: Colors.white),
            ),
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
  
  // 品詞文字列をWordCategoryに変換
  WordCategory _getWordCategory(String word) {
    // スペースを含む場合はフレーズとしてその他に分類
    if (word.contains(' ')) {
      return WordCategory.other;
    }
    
    final partOfSpeech = _getPartOfSpeech(word);
    switch (partOfSpeech) {
      case '名詞':
        return WordCategory.noun;
      case '動詞':
        return WordCategory.verb;
      case '形容詞':
        return WordCategory.adjective;
      case '副詞':
        return WordCategory.adverb;
      case '代名詞':
        return WordCategory.pronoun;
      case '前置詞':
        return WordCategory.preposition;
      case '接続詞':
        return WordCategory.conjunction;
      case '感動詞':
        return WordCategory.interjection;
      default:
        return WordCategory.other;
    }
  }
  
  // 品詞を判定する
  String _getPartOfSpeech(String word) {
    final lowerWord = word.toLowerCase();
    
    // 特殊な単語の処理（複数品詞を持つ単語）
    // 名詞/副詞
    if (['today', 'yesterday', 'tomorrow'].contains(lowerWord)) return '名詞'; // 最初の品詞を使用
    // 名詞/動詞
    if (['work', 'love'].contains(lowerWord)) return '名詞'; // 最初の品詞を使用
    // 動詞/前置詞
    if (lowerWord == 'like') return '動詞'; // 最初の品詞を使用
    // 所有格/目的格 - 代名詞として扱う
    if (lowerWord == 'her') return '代名詞';
    
    // 冠詞をその他として扱う（将来的に別カテゴリを作る可能性も）
    if (['a', 'an', 'the'].contains(lowerWord)) return 'その他';
    
    // よく使われる名詞（より具体的な単語から先に判定）
    final commonNouns = {
      'happiness', 'sadness', 'learning', 'morning', 'evening',
      'swimming', 'running', 'writing', 'reading', 'meeting', 'feeling',
      'time', 'person', 'year', 'way', 'day', 'man', 'thing', 'woman', 'life', 'child',
      'world', 'school', 'state', 'family', 'student', 'group', 'country', 'problem',
      'hand', 'part', 'place', 'case', 'week', 'company', 'system', 'program', 'question',
      'work', 'government', 'number', 'night', 'point', 'home', 'water', 'room', 'mother',
      'area', 'money', 'story', 'fact', 'month', 'lot', 'right', 'study', 'book', 'eye',
      'job', 'word', 'business', 'issue', 'side', 'kind', 'head', 'house', 'service',
      'friend', 'father', 'power', 'hour', 'game', 'line', 'end', 'member', 'law', 'car',
      'city', 'community', 'name', 'president', 'team', 'minute', 'idea', 'kid', 'body',
      'information', 'back', 'parent', 'face', 'others', 'level', 'office', 'door', 'health',
      'art', 'war', 'history', 'party', 'result', 'change', 'reason', 'research', 'girl',
      'guy', 'moment', 'air', 'teacher', 'force', 'education', 'foot', 'boy', 'age',
      'policy', 'process', 'music', 'market', 'sense', 'nation', 'plan', 'college',
      'interest', 'death', 'experience', 'effect', 'use', 'class', 'control', 'care',
      'field', 'development', 'role', 'effort', 'rate', 'heart', 'drug', 'show', 'leader',
      'light', 'voice', 'wife', 'whole', 'police', 'mind', 'price', 'report', 'decision',
      'son', 'hope', 'view', 'relationship', 'daughter', 'magazine', 'action', 'truth',
      'quality', 'rock', 'standard', 'hair', 'choice', 'gift', 'tool', 'message',
      'science', 'form', 'food', 'ability', 'staff', 'officer', 'article', 'department',
      'difference', 'goal', 'news', 'society', 'love', 'freedom', 'page', 'sound',
      'animal', 'culture', 'top', 'piece', 'record', 'picture', 'data', 'attention',
      'performance', 'knowledge', 'behavior', 'energy', 'note', 'memory', 'patient',
      'worker', 'pain', 'application', 'sun', 'product', 'income', 'rule', 'couple',
      'step', 'demand', 'statement', 'activity', 'practice', 'bank', 'support', 'event',
      'building', 'mouth', 'computer', 'blood', 'dollar', 'condition', 'wall', 'purpose',
      'map', 'sea', 'section', 'test', 'subject', 'space', 'board', 'oil', 'access',
      'garden', 'emergency', 'situation', 'attempt', 'date', 'link', 'post', 'star',
      'land', 'order', 'consequence', 'figure', 'sentence', 'nature', 'cell', 'population',
      'economy', 'hospital', 'growth', 'club', 'organization', 'pressure', 'response',
      'letter', 'loss', 'agreement', 'release', 'bird', 'opinion', 'credit', 'corner',
      'weight', 'self', 'desk', 'site', 'project', 'machine', 'hotel', 'method',
      'analysis', 'instance', 'cash', 'sample', 'understanding', 'training', 'advantage',
      'floor', 'associate', 'collection', 'rest', 'stress', 'bed', 'union', 'success',
      'concern', 'resource', 'speech', 'discussion', 'disease', 'operation', 'crime',
      'ball', 'forest', 'increase', 'attack', 'stock', 'version', 'violence', 'industry',
      'farm', 'battle', 'shoe', 'grade', 'context', 'committee', 'mistake', 'location',
      'sign', 'damage', 'distance', 'cloud', 'surface', 'direction', 'weapon',
      'technology', 'weather', 'structure', 'skill', 'beginning', 'actor', 'birth',
      'search', 'motor', 'boat', 'object', 'attitude', 'labor', 'truck', 'sister',
      'dream', 'conference', 'lady', 'brain', 'investment', 'conversation', 'profit',
      'restaurant', 'property', 'ship', 'detail', 'competition', 'term', 'film',
      'introduction', 'literature', 'speed', 'connection', 'agency', 'responsibility',
      'administration', 'stone', 'generation', 'cancer', 'proposal', 'scale', 'score',
      'injury', 'lesson', 'crowd', 'estimate', 'flow', 'mission', 'meal', 'airport',
      'emotion', 'depression', 'profession', 'stage', 'wine', 'expert', 'hole', 'review',
      'vision', 'resolution', 'fashion', 'salary', 'reaction', 'atmosphere', 'cycle',
      'bread', 'decade', 'priority', 'function', 'yesterday', 'factory', 'vehicle',
      'coffee', 'extension', 'assistance', 'reduction', 'dessert', 'horror', 'passage',
      'medicine', 'flight', 'mountain', 'observation', 'whisper', 'childhood', 'payment',
      'journey', 'flower', 'exchange', 'weekend', 'respect', 'communication', 'lake',
      'appointment', 'impression', 'independence', 'sugar', 'lunch', 'river', 'dinner',
      'improvement', 'tradition', 'virus', 'delivery', 'expression', 'foundation',
      'painting', 'penalty', 'piano', 'beach', 'perception', 'protection', 'creation',
      'fee', 'owner', 'accident', 'insurance', 'scene', 'image', 'traffic', 'career',
      'leadership', 'photo', 'recipe', 'studio', 'topic', 'storm', 'opportunity',
      'comparison', 'tissue', 'revenue', 'visitor', 'kitchen', 'university', 'height',
      'assessment', 'guidance', 'guest', 'contract', 'warning', 'climate', 'ice',
      'furniture', 'spouse', 'symbol', 'audience', 'drawer', 'client', 'feedback',
      'quantity', 'bicycle', 'shoulder', 'cat', 'button', 'distribution', 'request',
      'permission', 'challenge', 'judgment', 'produce', 'knife', 'card', 'volume',
      'moon', 'conclusion', 'aspect', 'shirt', 'cabinet', 'dog', 'editor', 'period',
      'chair', 'fish', 'election', 'winter', 'summer', 'spring', 'autumn', 'fall',
      'season', 'january', 'february', 'march', 'april', 'may', 'june', 'july',
      'august', 'september', 'october', 'november', 'december', 'monday', 'tuesday',
      'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'journal', 'diary',
      'memo', 'email', 'text', 'call', 'phone', 'smartphone', 'laptop', 'tablet',
      'keyboard', 'mouse', 'screen', 'monitor', 'printer', 'paper', 'pen', 'pencil',
      'notebook', 'calendar', 'clock', 'watch', 'second', 'afternoon', 'midnight',
      'noon', 'breakfast', 'drink', 'tea', 'juice', 'milk', 'rice', 'meat', 'vegetable',
      'fruit', 'apple', 'orange', 'banana', 'grape', 'strawberry', 'cherry', 'peach',
      'homework', 'assignment', 'presentation', 'interview', 'debate', 'argument',
      'disagreement', 'answer', 'solution', 'theme', 'thought', 'perspective',
      'belief', 'value', 'principle', 'concept', 'theory', 'hypothesis', 'evidence',
      'proof', 'reason', 'cause', 'outcome', 'impact', 'influence', 'factor',
      'element', 'component', 'share', 'percentage', 'amount', 'total', 'sum',
      'average', 'mean', 'median', 'mode', 'range', 'length', 'width', 'depth',
      'size', 'shape', 'pattern', 'design', 'style', 'trend', 'color', 'colour',
      'red', 'blue', 'green', 'yellow', 'pink', 'black', 'white', 'gray', 'grey',
      'brown', 'gold', 'silver', 'copper', 'bronze'
    };
    
    // よく使われる動詞
    final commonVerbs = {
      'be', 'have', 'do', 'say', 'go', 'get', 'make', 'know', 'think', 'take',
      'see', 'come', 'want', 'use', 'find', 'give', 'tell', 'work', 'call', 'try',
      'ask', 'need', 'feel', 'become', 'leave', 'put', 'mean', 'keep', 'let', 'begin',
      'seem', 'help', 'show', 'hear', 'play', 'run', 'move', 'live', 'believe', 'bring',
      'happen', 'write', 'sit', 'stand', 'lose', 'pay', 'meet', 'include', 'continue',
      'set', 'learn', 'change', 'lead', 'understand', 'watch', 'follow', 'stop', 'create',
      'speak', 'read', 'spend', 'grow', 'open', 'walk', 'win', 'teach', 'offer', 'remember',
      'love', 'consider', 'appear', 'buy', 'wait', 'serve', 'die', 'send', 'expect', 'stay',
      'fall', 'cut', 'reach', 'kill', 'raise', 'pass', 'sell', 'require', 'report', 'decide',
      'pull', 'break', 'explain', 'hope', 'develop', 'carry', 'drive', 'wear', 'support',
      'hold', 'cause', 'produce', 'provide', 'throw', 'accept', 'allow', 'answer', 'achieve',
      'agree', 'arrive', 'attack', 'avoid', 'bear', 'beat', 'belong', 'burn', 'clean',
      'collect', 'compare', 'complain', 'complete', 'contain', 'control', 'cook', 'copy',
      'correct', 'cost', 'cover', 'crash', 'damage', 'dance', 'deliver', 'depend', 'describe',
      'design', 'destroy', 'disappear', 'discover', 'discuss', 'divide', 'draw', 'dream',
      'drink', 'drop', 'earn', 'eat', 'enjoy', 'enter', 'examine', 'exist', 'express',
      'fail', 'fight', 'fill', 'finish', 'fit', 'fix', 'fly', 'forget', 'forgive',
      'found', 'gain', 'guess', 'handle', 'hang', 'hate', 'hide', 'hit', 'hurt',
      'identify', 'imagine', 'improve', 'increase', 'indicate', 'influence', 'inform',
      'intend', 'introduce', 'invest', 'invite', 'join', 'jump', 'kick', 'kiss', 'laugh',
      'lie', 'lift', 'link', 'listen', 'look', 'manage', 'mark', 'marry', 'match',
      'measure', 'mention', 'mind', 'miss', 'mix', 'obtain', 'occur', 'operate', 'order',
      'own', 'pack', 'paint', 'park', 'participate', 'perform', 'pick', 'place', 'plan',
      'point', 'practice', 'prefer', 'prepare', 'present', 'press', 'prevent', 'print',
      'promise', 'protect', 'prove', 'push', 'receive', 'recognize', 'record', 'reduce',
      'refer', 'reflect', 'refuse', 'regard', 'relate', 'release', 'remain', 'remove',
      'rent', 'repair', 'repeat', 'replace', 'reply', 'represent', 'request', 'rescue',
      'rest', 'result', 'return', 'reveal', 'ride', 'ring', 'rise', 'risk', 'roll',
      'save', 'search', 'seek', 'select', 'separate', 'settle', 'shake', 'share', 'shoot',
      'shout', 'shut', 'sign', 'sing', 'sink', 'sleep', 'slide', 'smell', 'smile',
      'smoke', 'solve', 'sort', 'sound', 'spell', 'spread', 'start', 'steal', 'stick',
      'study', 'succeed', 'suffer', 'suggest', 'supply', 'surprise', 'survive', 'swim',
      'switch', 'talk', 'taste', 'test', 'thank', 'touch', 'train', 'travel', 'treat',
      'trust', 'turn', 'type', 'unite', 'visit', 'vote', 'wake', 'warn', 'wash',
      'waste', 'weigh', 'welcome', 'wish', 'wonder', 'worry', 'wound', 'wrap',
      'is', 'are', 'was', 'were', 'been', 'am', 'has', 'had', 'does', 'did'
    };
    
    // よく使われる形容詞
    final commonAdjectives = {
      'good', 'new', 'first', 'last', 'long', 'great', 'little', 'own', 'other', 'old',
      'right', 'big', 'high', 'different', 'small', 'large', 'next', 'early', 'young',
      'important', 'few', 'public', 'bad', 'same', 'able', 'human', 'sure', 'better',
      'best', 'free', 'whole', 'full', 'hot', 'cold', 'happy', 'easy', 'strong',
      'special', 'clear', 'recent', 'late', 'single', 'medical', 'current', 'wrong',
      'private', 'past', 'foreign', 'fine', 'common', 'poor', 'natural', 'significant',
      'similar', 'deep', 'available', 'likely', 'short', 'personal', 'open', 'red',
      'difficult', 'white', 'various', 'entire', 'close', 'international', 'legal',
      'simple', 'environmental', 'financial', 'serious', 'ready', 'necessary', 'physical',
      'blue', 'positive', 'cultural', 'military', 'original', 'successful', 'basic',
      'willing', 'traditional', 'safe', 'direct', 'civil', 'chief', 'normal', 'secret',
      'separate', 'responsible', 'previous', 'healthy', 'complete', 'global', 'aware',
      'commercial', 'huge', 'popular', 'worth', 'official', 'critical', 'possible',
      'lost', 'creative', 'correct', 'beautiful', 'final', 'quiet', 'true', 'modern',
      'confident', 'angry', 'effective', 'visual', 'wide', 'busy', 'fair', 'rich',
      'useful', 'active', 'cool', 'comfortable', 'appropriate', 'warm', 'proud',
      'fresh', 'empty', 'amazing', 'tiny', 'prime', 'rare', 'terrible', 'immediate',
      'weird', 'careful', 'tight', 'sad', 'complex', 'severe', 'funny', 'strange',
      'tall', 'proper', 'front', 'constant', 'wonderful', 'sudden', 'acceptable',
      'reasonable', 'mental', 'competitive', 'technical', 'ordinary', 'cheap',
      'concerned', 'powerful', 'practical', 'dangerous', 'grand', 'brief', 'typical',
      'exciting', 'dear', 'unique', 'classic', 'educational', 'electronic', 'opposite',
      'annual', 'regular', 'capable', 'relative', 'accurate', 'urban', 'mad',
      'sexual', 'massive', 'interesting', 'academic', 'distant', 'brilliant',
      'narrow', 'sensitive', 'casual', 'obvious', 'thick', 'inner', 'joint', 'moral',
      'wild', 'pregnant', 'minimum', 'honest', 'impressive', 'friendly', 'interior',
      'guilty', 'internal', 'initial', 'famous', 'impossible', 'visible', 'permanent',
      'emotional', 'afraid', 'ancient', 'expensive', 'formal', 'remote', 'dark',
      'independent', 'consistent', 'daily', 'intense', 'musical', 'sharp', 'boring',
      'pretty', 'sick', 'brown', 'solid', 'objective', 'attractive', 'essential',
      'flat', 'loud', 'sufficient', 'criminal', 'firm', 'heavy', 'thin', 'literary',
      'smart', 'aggressive', 'extreme', 'distinct', 'resident', 'cute', 'soft',
      'potential', 'mobile', 'rough', 'spiritual', 'actual', 'mixed', 'maximum',
      'green', 'conventional', 'yellow', 'bright', 'outstanding', 'familiar',
      'usual', 'eastern', 'external', 'psychological', 'quick', 'broken', 'suitable',
      'anxious', 'comprehensive', 'fast', 'federal', 'unable', 'wooden', 'weekly',
      'super', 'intelligent', 'stupid', 'tough', 'crazy', 'equal', 'frequent',
      'rural', 'junior', 'historical', 'golden', 'raw', 'unlikely', 'southern',
      'mild', 'clean', 'evil', 'smooth', 'contemporary', 'residential', 'steady',
      'ideal', 'lucky', 'mysterious', 'efficient', 'shiny', 'bitter', 'dirty',
      'excited', 'gross', 'hungry', 'romantic', 'precise', 'mature', 'artificial',
      'moderate', 'structural', 'logical', 'racial', 'naval', 'domestic', 'brave',
      'calm', 'orange', 'exceptional', 'protective', 'marked', 'opposed', 'gray',
      'continuing', 'exact', 'pink', 'olympic', 'purple', 'developing', 'blind',
      'shared', 'increased', 'elaborate', 'immense', 'occupied', 'plain', 'wealthy',
      'invisible', 'insane', 'ill', 'voluntary', 'patient', 'tender', 'valid',
      'advanced', 'straight', 'convinced', 'rational', 'automatic', 'pleasant',
      'devoted', 'scared', 'ethical', 'continued', 'molecular', 'extended',
      'focused', 'biological', 'ethnic', 'dominant', 'mutual', 'unfair', 'alert',
      'silent', 'awful', 'determined', 'frozen', 'spare', 'gentle', 'sacred', 'bare'
    };
    
    // よく使われる副詞
    final commonAdverbs = {
      'not', 'also', 'very', 'often', 'however', 'too', 'usually', 'really', 'early',
      'never', 'always', 'sometimes', 'together', 'likely', 'simply', 'generally',
      'instead', 'actually', 'again', 'rather', 'almost', 'especially', 'ever',
      'quickly', 'probably', 'already', 'below', 'directly', 'therefore', 'else',
      'thus', 'somewhat', 'anyway', 'beyond', 'forward', 'yesterday', 'clearly',
      'recently', 'tomorrow', 'nearly', 'properly', 'closely', 'easily', 'indeed',
      'necessarily', 'possibly', 'finally', 'certainly', 'slowly', 'otherwise',
      'currently', 'extremely', 'entirely', 'obviously', 'frequently', 'fully',
      'mostly', 'potentially', 'slightly', 'approximately', 'seriously', 'previously',
      'highly', 'immediately', 'relatively', 'strongly', 'honestly', 'technically',
      'truly', 'virtually', 'equally', 'greatly', 'typically', 'effectively',
      'elsewhere', 'occasionally', 'essentially', 'absolutely', 'dramatically',
      'naturally', 'increasingly', 'meanwhile', 'furthermore', 'literally',
      'primarily', 'gradually', 'partly', 'suddenly', 'rarely', 'hopefully',
      'eventually', 'normally', 'surprisingly', 'regularly', 'similarly', 'basically',
      'unfortunately', 'largely', 'originally', 'briefly', 'personally', 'apparently',
      'ultimately', 'carefully', 'rapidly', 'fairly', 'aside', 'altogether', 'merely',
      'automatically', 'heavily', 'terribly', 'gently', 'publicly', 'completely',
      'widely', 'totally', 'constantly', 'significantly', 'precisely', 'deeply',
      'hardly', 'badly', 'nowhere', 'weekly', 'initially', 'everywhere', 'somehow',
      'strictly', 'alternatively', 'simultaneously', 'nowadays', 'subsequently',
      'traditionally', 'continually', 'secondly', 'desperately', 'consequently',
      'ordinarily', 'exclusively', 'enormously', 'notably', 'remarkably',
      'understandably', 'genuinely', 'reasonably', 'undoubtedly', 'admittedly',
      'supposedly', 'urgently', 'firstly', 'lastly', 'thirdly', 'incredibly',
      'considerably', 'actively', 'barely', 'historically', 'legally', 'officially',
      'commonly', 'mentally', 'solely', 'tightly', 'locally', 'seemingly',
      'additionally', 'physically', 'financially', 'emotionally', 'roughly',
      'politically', 'sufficiently', 'annually', 'firmly', 'extensively',
      'temporarily', 'separately', 'inevitably', 'repeatedly', 'safely', 'quietly',
      'professionally', 'newly', 'partially', 'randomly', 'openly', 'socially',
      'definitely', 'thoroughly', 'frankly', 'peacefully', 'independently',
      'deliberately', 'lightly', 'steadily', 'fortunately', 'sharply', 'successfully',
      'universally', 'conveniently', 'evenly', 'anxiously', 'positively',
      'accordingly', 'internationally', 'violently', 'continuously', 'wildly',
      'lately', 'perfectly', 'correctly', 'negatively', 'softly', 'manually',
      'collectively', 'experimentally', 'beautifully', 'swiftly', 'promptly',
      'silently', 'namely', 'economically', 'fiercely', 'calmly', 'boldly', 'kindly',
      'nonetheless', 'neatly', 'bitterly', 'enthusiastically', 'smoothly', 'luckily',
      'plainly', 'warmly', 'painfully', 'politely', 'curiously', 'generously',
      'patiently', 'privately', 'gratefully', 'permanently', 'individually',
      'indirectly', 'utterly', 'mutually', 'harshly', 'poorly', 'freely', 'globally',
      'broadly', 'halfway', 'truthfully', 'cautiously', 'intentionally', 'happily',
      'nervously', 'creatively', 'unusually', 'ideally', 'awkwardly', 'comfortably',
      'consistently', 'electronically', 'brutally', 'eagerly', 'justly', 'madly',
      'loosely', 'explicitly', 'brightly', 'instantly', 'loudly', 'artificially',
      'steadily', 'formally', 'sadly', 'wisely', 'dangerously', 'doubly',
      'accidentally', 'rightly', 'expertly', 'crazily'
    };
    
    // よく使われる代名詞
    final commonPronouns = {
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
      'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours',
      'theirs', 'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves',
      'yourselves', 'themselves', 'this', 'that', 'these', 'those', 'who', 'whom',
      'whose', 'which', 'what', 'where', 'when', 'why', 'how', 'someone', 'somebody',
      'anyone', 'anybody', 'everyone', 'everybody', 'no one', 'nobody', 'something',
      'anything', 'everything', 'nothing', 'somewhere', 'anywhere', 'everywhere',
      'nowhere', 'whoever', 'whatever', 'wherever', 'whenever', 'whichever', 'each',
      'every', 'either', 'neither', 'both', 'all', 'some', 'any', 'none', 'few',
      'many', 'several', 'much', 'more', 'most', 'other', 'others', 'another',
      'such', 'one', 'ones'
    };
    
    // よく使われる前置詞
    final commonPrepositions = {
      'of', 'in', 'to', 'for', 'with', 'on', 'at', 'from', 'by', 'about', 'as',
      'into', 'through', 'during', 'before', 'after', 'above', 'below', 'up',
      'down', 'out', 'off', 'over', 'under', 'again', 'between', 'among', 'without',
      'within', 'along', 'following', 'across', 'behind', 'beyond', 'plus', 'except',
      'but', 'until', 'upon', 'against', 'around', 'including', 'despite', 'toward',
      'towards', 'throughout', 'concerning', 'regarding', 'via', 'per', 'like',
      'unlike', 'than', 'versus', 'amongst', 'beneath', 'beside', 'besides',
      'inside', 'outside', 'onto', 'underneath', 'amid', 'past', 'worth', 'near',
      'alongside', 'aboard', 'according', 'opposite', 'aside', 'circa', 'considering',
      'due', 'excepting', 'failing', 'given', 'granted', 'less', 'minus', 'next',
      'notwithstanding', 'pending', 'round', 'save', 'saving', 'since', 'till',
      'unto', 'versus'
    };
    
    // よく使われる接続詞
    final commonConjunctions = {
      'and', 'but', 'or', 'so', 'because', 'when', 'if', 'while', 'although', 'though',
      'since', 'unless', 'until', 'whether', 'whereas', 'wherever', 'whenever',
      'however', 'therefore', 'moreover', 'furthermore', 'nevertheless', 'nonetheless',
      'meanwhile', 'otherwise', 'yet', 'for', 'nor', 'either', 'neither', 'both',
      'not only', 'but also', 'as', 'than', 'rather', 'that', 'whatever', 'whichever',
      'whoever', 'whomever', 'whose', 'where', 'after', 'as if', 'as long as',
      'as soon as', 'as though', 'even if', 'even though', 'in order that', 'once',
      'provided that', 'so that', 'till', 'hence', 'thus', 'consequently'
    };
    
    // よく使われる感動詞
    final commonInterjections = {
      'oh', 'ah', 'eh', 'hey', 'hi', 'hello', 'bye', 'goodbye', 'please', 'thanks',
      'sorry', 'excuse', 'pardon', 'wow', 'ooh', 'ouch', 'ugh', 'hmm', 'well', 'yes',
      'no', 'yeah', 'nope', 'yep', 'okay', 'ok', 'alright', 'sure', 'certainly',
      'indeed', 'really', 'actually', 'basically', 'seriously', 'honestly', 'frankly',
      'clearly', 'obviously', 'apparently', 'evidently', 'surprisingly',
      'unfortunately', 'fortunately', 'luckily', 'sadly', 'happily', 'amazingly',
      'interestingly', 'curiously', 'strangely', 'oddly', 'weirdly', 'funnily',
      'ironically', 'paradoxically', 'coincidentally', 'incidentally', 'naturally',
      'normally', 'aha', 'oops', 'thank', 'alas', 'bravo', 'encore', 'eureka',
      'hooray', 'hurray', 'shh', 'phew', 'whoa', 'yikes', 'yippee', 'bingo',
      'cheers', 'congrats', 'congratulations', 'darn', 'dang', 'gosh', 'goodness',
      'gracious', 'jeez', 'sheesh', 'shoot', 'shucks', 'whoops', 'yay'
    };
    
    // まず完全一致を確認（より具体的な品詞から確認）
    if (commonInterjections.contains(lowerWord)) return '感動詞';
    if (commonPronouns.contains(lowerWord)) return '代名詞';
    if (commonPrepositions.contains(lowerWord)) return '前置詞';
    if (commonConjunctions.contains(lowerWord)) return '接続詞';
    if (commonAdverbs.contains(lowerWord)) return '副詞';
    if (commonAdjectives.contains(lowerWord)) return '形容詞';
    if (commonNouns.contains(lowerWord)) return '名詞';
    if (commonVerbs.contains(lowerWord)) return '動詞';
    
    // 副詞の接尾辞（-lyで終わる）を先にチェック
    if (lowerWord.endsWith('ly') && lowerWord.length > 2) {
      // -lyを除いた部分が形容詞かどうか確認
      final withoutLy = lowerWord.substring(0, lowerWord.length - 2);
      if (commonAdjectives.contains(withoutLy) || 
          commonAdjectives.contains(withoutLy + 'e') || // simpleのような単語
          commonAdjectives.contains(withoutLy.substring(0, withoutLy.length - 1) + 'y')) { // happyのような単語
        return '副詞';
      }
      // それ以外の-lyで終わる単語も副詞の可能性が高い
      return '副詞';
    }
    
    // 形容詞の接尾辞
    if (lowerWord.endsWith('able') || lowerWord.endsWith('ible') ||
        lowerWord.endsWith('ful') || lowerWord.endsWith('less') ||
        lowerWord.endsWith('ous') || lowerWord.endsWith('ious') ||
        lowerWord.endsWith('ive') || lowerWord.endsWith('ic') ||
        lowerWord.endsWith('al') || lowerWord.endsWith('ical') ||
        lowerWord.endsWith('ish') || lowerWord.endsWith('like')) {
      return '形容詞';
    }
    
    // 名詞の接尾辞（動名詞の判定より前に）
    if (lowerWord.endsWith('tion') || lowerWord.endsWith('sion') || 
        lowerWord.endsWith('ment') || lowerWord.endsWith('ness') || 
        lowerWord.endsWith('ity') || lowerWord.endsWith('ance') || 
        lowerWord.endsWith('ence') || lowerWord.endsWith('ship') ||
        lowerWord.endsWith('hood') || lowerWord.endsWith('dom') ||
        lowerWord.endsWith('ism') || lowerWord.endsWith('ist') ||
        lowerWord.endsWith('er') && !commonVerbs.contains(lowerWord) ||
        lowerWord.endsWith('or') && !commonVerbs.contains(lowerWord)) {
      return '名詞';
    }
    
    // 動詞の活用形を確認（最後に）
    if (lowerWord.endsWith('ing')) {
      // -ing形は動詞の可能性が高い（ただし動名詞除く）
      final baseForm = lowerWord.substring(0, lowerWord.length - 3);
      if (commonVerbs.contains(baseForm) || 
          commonVerbs.contains(baseForm + 'e') || // makeのような単語
          commonVerbs.contains(baseForm.substring(0, baseForm.length - 1))) { // runningのような単語
        return '動詞';
      }
      // 動名詞として名詞の可能性
      if (!commonVerbs.contains(lowerWord)) {
        return '名詞';
      }
    }
    
    if (lowerWord.endsWith('ed')) {
      // -ed形は動詞の過去形/過去分詞の可能性が高い
      final baseForm = lowerWord.substring(0, lowerWord.length - 2);
      if (commonVerbs.contains(baseForm) || 
          commonVerbs.contains(baseForm + 'e')) { // likedのような単語
        return '動詞';
      }
    }
    
    if (lowerWord.endsWith('s') && lowerWord.length > 2) {
      // 三単現のsかもしれない
      final baseForm = lowerWord.substring(0, lowerWord.length - 1);
      if (commonVerbs.contains(baseForm)) {
        return '動詞';
      }
      // -esで終わる場合
      if (lowerWord.endsWith('es') && lowerWord.length > 3) {
        final baseForm2 = lowerWord.substring(0, lowerWord.length - 2);
        if (commonVerbs.contains(baseForm2)) {
          return '動詞';
        }
      }
    }
    
    // フレーズ・慣用句の判定
    if (word.contains(' ')) {
      // 複数単語の場合はその他として扱う
      return 'その他';
    }
    
    // デフォルト
    return 'その他';
  }

  Future<Map<String, DateTime?>?> _showDateRangePicker(BuildContext context, DateTime? initialStart, DateTime? initialEnd) async {
    DateTime? startDate = initialStart;
    DateTime? endDate = initialEnd;
    
    return await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '期間を選択',
                          style: AppTheme.headline3,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 選択された日付の表示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            startDate != null
                                ? '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}'
                                : '開始日',
                            style: AppTheme.body1.copyWith(
                              color: startDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('〜', style: AppTheme.body1),
                          const SizedBox(width: 16),
                          Text(
                            endDate != null
                                ? '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}'
                                : '終了日',
                            style: AppTheme.body1.copyWith(
                              color: endDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // カレンダー表示
                    Container(
                      height: 350,
                      child: TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime.now(),
                        focusedDay: startDate ?? DateTime.now(),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        rangeStartDay: startDate,
                        rangeEndDay: endDate,
                        onRangeSelected: (start, end, focused) {
                          setDialogState(() {
                            startDate = start;
                            endDate = end;
                          });
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setDialogState(() {
                            if (startDate == null || (startDate != null && endDate != null)) {
                              // 最初の選択、または両方選択済みの場合は新しい選択を開始
                              startDate = selectedDay;
                              endDate = null;
                            } else if (endDate == null) {
                              // 2回目の選択
                              if (selectedDay.isBefore(startDate!)) {
                                // 開始日より前を選択した場合は入れ替える
                                endDate = startDate;
                                startDate = selectedDay;
                              } else {
                                endDate = selectedDay;
                              }
                            }
                          });
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          rangeHighlightColor: AppTheme.primaryColor.withOpacity(0.1),
                          rangeStartDecoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          withinRangeDecoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          withinRangeTextStyle: TextStyle(
                            color: AppTheme.textPrimary,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(
                            color: AppTheme.textPrimary,
                          ),
                          weekendTextStyle: TextStyle(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: AppTheme.textPrimary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: AppTheme.textPrimary,
                          ),
                          titleTextStyle: AppTheme.headline3,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          weekendStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // ボタン
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setDialogState(() {
                                startDate = null;
                                endDate = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'クリア',
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
                              Navigator.pop(context, {
                                'start': startDate,
                                'end': endDate,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('適用'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startWordStudySession() {
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
    
    // 単語リストをシャッフル
    final shuffledWords = List<Word>.from(sessionWords)..shuffle();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordStudySessionScreen(words: shuffledWords),
      ),
    ).then((_) => _loadWords());
  }
}

class _WordCardItem extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;
  final VoidCallback onToggleLearned;

  const _WordCardItem({
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.japanese,
                          style: AppTheme.body2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.info.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          word.category.displayName,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                    widget.word.category.displayName,
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
            
            
            const SizedBox(height: 16),
            
            // 追加日
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '追加日: ${widget.word.createdAt.year}年${widget.word.createdAt.month}月${widget.word.createdAt.day}日',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
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
    // 上の_LearningScreenStateクラスの_getPartOfSpeechメソッドを使用
    final parent = context.findAncestorStateOfType<_LearningScreenState>();
    if (parent != null) {
      return parent._getPartOfSpeech(word);
    }
    // フォールバック
    return 'その他';
  }
  
  // 品詞文字列をWordCategoryに変換
  WordCategory _getWordCategory(String word) {
    // スペースを含む場合はフレーズ
    if (word.contains(' ')) {
      return WordCategory.other;
    }
    
    final partOfSpeech = _getPartOfSpeech(word);
    switch (partOfSpeech) {
      case '名詞':
        return WordCategory.noun;
      case '動詞':
        return WordCategory.verb;
      case '形容詞':
        return WordCategory.adjective;
      case '副詞':
        return WordCategory.adverb;
      case '代名詞':
        return WordCategory.pronoun;
      case '前置詞':
        return WordCategory.preposition;
      case '接続詞':
        return WordCategory.conjunction;
      default:
        return WordCategory.other;
    }
  }
  
}