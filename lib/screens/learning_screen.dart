import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';

// Extension to add display name to WordCategory
extension WordCategoryExtension on WordCategory {
  String get displayName {
    switch (this) {
      case WordCategory.noun:
        return '名詞';
      case WordCategory.verb:
        return '動詞';
      case WordCategory.adjective:
        return '形容詞';
      case WordCategory.adverb:
        return '副詞';
      case WordCategory.pronoun:
        return '代名詞';
      case WordCategory.preposition:
        return '前置詞';
      case WordCategory.conjunction:
        return '接続詞';
      case WordCategory.interjection:
        return '感動詞';
      case WordCategory.other:
        return 'その他';
    }
  }
}

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
  final bool _showNew = true; // NEW表示フラグ
  final bool _showFailed = true; // ×表示フラグ
  
  // フィルター関連の状態
  Set<WordCategory> _selectedCategories = WordCategory.values.toSet();
  Set<int> _selectedMasteryLevels = {0, 1, 2};
  DateTime? _startDate;
  DateTime? _endDate;

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  
  String _getHeaderTitle() {
    if (widget.initialCategory != null) {
      return widget.initialCategory!.displayName;
    } else {
      return 'すべて';
    }
  }

  bool _hasActiveFilters() {
    return _selectedCategories.length != WordCategory.values.length ||
           _selectedMasteryLevels.length != 3 ||
           _startDate != null ||
           _endDate != null;
  }

  List<Word> _getFilteredWords(List<Word> words) {
    var filtered = words.where((word) {
      // カテゴリフィルター
      if (!_selectedCategories.contains(word.category)) {
        return false;
      }
      
      // 習得レベルフィルター
      if (!_selectedMasteryLevels.contains(word.masteryLevel)) {
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
    
    return filtered;
  }

  WordCategory _getCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'noun':
        return WordCategory.noun;
      case 'verb':
        return WordCategory.verb;
      case 'adjective':
        return WordCategory.adjective;
      case 'adverb':
        return WordCategory.adverb;
      default:
        return WordCategory.other;
    }
  }

  Future<void> _removeDuplicates() async {
    final uniqueWords = <String, Word>{};
    final duplicateIds = <String>[];
    
    for (final word in _allWords) {
      final key = word.english.toLowerCase();
      if (uniqueWords.containsKey(key)) {
        duplicateIds.add(word.id);
      } else {
        uniqueWords[key] = word;
      }
    }
    
    if (duplicateIds.isNotEmpty) {
      for (final id in duplicateIds) {
        await StorageService.deleteWord(id);
      }
      
      await _loadWords();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${duplicateIds.length}件の重複単語を削除しました'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('重複単語はありません'),
          ),
        );
      }
    }
  }

  Future<void> _updateWordCategories() async {
    int updatedCount = 0;
    
    for (final word in _allWords) {
      final newCategory = _determineWordCategory(word.english);
      if (word.category != newCategory) {
        final updatedWord = Word(
          id: word.id,
          english: word.english,
          japanese: word.japanese,
          category: newCategory,
          example: word.example,
          diaryEntryId: word.diaryEntryId,
          createdAt: word.createdAt,
          masteryLevel: word.masteryLevel,
          reviewCount: word.reviewCount,
          lastReviewedAt: word.lastReviewedAt,
        );
        await StorageService.saveWord(updatedWord);
        updatedCount++;
      }
    }
    
    if (updatedCount > 0) {
      await _loadWords();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$updatedCount件の単語のカテゴリを更新しました'),
        ),
      );
    }
  }

  WordCategory _determineWordCategory(String word) {
    final lowered = word.toLowerCase();
    
    if (lowered.endsWith('ing') || lowered.endsWith('ed') || 
        lowered.endsWith('s') && !lowered.endsWith('ss')) {
      return WordCategory.verb;
    } else if (lowered.endsWith('ly')) {
      return WordCategory.adverb;
    } else if (lowered.endsWith('ful') || lowered.endsWith('less') || 
               lowered.endsWith('ous') || lowered.endsWith('ive')) {
      return WordCategory.adjective;
    } else if (lowered.endsWith('tion') || lowered.endsWith('sion') || 
               lowered.endsWith('ment') || lowered.endsWith('ness') || 
               lowered.endsWith('ity')) {
      return WordCategory.noun;
    }
    
    return WordCategory.other;
  }

  Future<void> _removeUnwantedWords() async {
    final unwantedWords = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being'};
    final idsToRemove = <String>[];
    
    for (final word in _allWords) {
      if (unwantedWords.contains(word.english.toLowerCase())) {
        idsToRemove.add(word.id);
      }
    }
    
    if (idsToRemove.isNotEmpty) {
      for (final id in idsToRemove) {
        await StorageService.deleteWord(id);
      }
      
      await _loadWords();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${idsToRemove.length}件の不要な単語を削除しました'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除対象の単語はありません'),
          ),
        );
      }
    }
  }

  void _startWordStudySession() {
    final filteredWords = _getFilteredWords(_allWords);
    final studyWords = filteredWords.where((word) => word.masteryLevel < 2).toList();
    
    if (studyWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('学習する単語がありません'),
        ),
      );
      return;
    }
    
    // Navigate to study session screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordStudySessionScreen(
          words: studyWords,
          onComplete: () async {
            await _loadWords();
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Word> words, String emptyMessage) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (words.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: AppTheme.body1.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );
    }
    
    return _buildCardList(words);
  }

  Widget _buildLearningTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '学習機能',
              style: AppTheme.display3,
            ),
            const SizedBox(height: 8),
            Text(
              'フラッシュカード形式で単語を学習できます',
              style: AppTheme.body2.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startWordStudySession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('学習を開始'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<Word> words) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCardItem(
          word: word,
          onTap: () => _showWordDetail(word),
          onUpdateMastery: (level) => _updateWordMastery(word, level),
        );
      },
    );
  }

  Future<void> _updateWordMastery(Word word, int level) async {
    final updatedWord = Word(
      id: word.id,
      english: word.english,
      japanese: word.japanese,
      category: word.category,
      example: word.example,
      diaryEntryId: word.diaryEntryId,
      createdAt: word.createdAt,
      masteryLevel: level,
      reviewCount: word.reviewCount + 1,
      lastReviewedAt: DateTime.now(),
    );
    
    await StorageService.saveWord(updatedWord);
    await _loadWords();
  }

  void _showWordDetail(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WordDetailModal(
        word: word,
        onUpdate: (updatedWord) async {
          await StorageService.saveWord(updatedWord);
          await _loadWords();
        },
        onDelete: () async {
          await StorageService.deleteWord(word.id);
          await _loadWords();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_getHeaderTitle()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters() 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showFilterDialog(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
              PopupMenuItem<String>(
                value: 'remove_duplicates',
                child: Row(
                  children: const [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('重複単語を削除'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'update_categories',
                child: Row(
                  children: const [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('カテゴリを自動更新'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'remove_unwanted_words',
                child: Row(
                  children: const [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 8),
                    Text('不要な単語を削除'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '学習中'),
              Tab(text: '学習'),
              Tab(text: '習得済み'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  _getFilteredWords(_allWords.where((word) => word.masteryLevel < 2).toList()),
                  '学習中の単語がありません',
                ),
                _buildLearningTab(),
                _buildTabContent(
                  _getFilteredWords(_allWords.where((word) => word.masteryLevel == 2).toList()),
                  '習得済みの単語がありません',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startWordStudySession,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.play_arrow),
        label: const Text('学習を開始'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: WordCategory.values.map((category) {
                  return FilterChip(
                    label: Text(category.displayName),
                    selected: _selectedCategories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('習得レベル', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('未学習'),
                    selected: _selectedMasteryLevels.contains(0),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMasteryLevels.add(0);
                        } else {
                          _selectedMasteryLevels.remove(0);
                        }
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  FilterChip(
                    label: const Text('学習中'),
                    selected: _selectedMasteryLevels.contains(1),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMasteryLevels.add(1);
                        } else {
                          _selectedMasteryLevels.remove(1);
                        }
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  FilterChip(
                    label: const Text('習得済み'),
                    selected: _selectedMasteryLevels.contains(2),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMasteryLevels.add(2);
                        } else {
                          _selectedMasteryLevels.remove(2);
                        }
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategories = WordCategory.values.toSet();
                _selectedMasteryLevels = {0, 1, 2};
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('リセット'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// Word card item widget
class _WordCardItem extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;
  final Function(int) onUpdateMastery;

  const _WordCardItem({
    required this.word,
    required this.onTap,
    required this.onUpdateMastery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.english,
                      style: AppTheme.heading2,
                    ),
                    if (word.japanese != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.japanese!,
                        style: AppTheme.body2.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildMasteryButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasteryButton(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (word.masteryLevel) {
      case 0:
        icon = Icons.close;
        color = Theme.of(context).colorScheme.error;
        break;
      case 1:
        icon = Icons.change_history;
        color = Colors.orange;
        break;
      case 2:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      default:
        icon = Icons.close;
        color = Theme.of(context).colorScheme.error;
    }
    
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () {
        final nextLevel = (word.masteryLevel + 1) % 3;
        onUpdateMastery(nextLevel);
      },
    );
  }
}

// Word detail modal
class _WordDetailModal extends StatefulWidget {
  final Word word;
  final Function(Word) onUpdate;
  final VoidCallback onDelete;

  const _WordDetailModal({
    required this.word,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_WordDetailModal> createState() => _WordDetailModalState();
}

class _WordDetailModalState extends State<_WordDetailModal> {
  late TextEditingController _japaneseController;
  late TextEditingController _exampleController;
  late WordCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _japaneseController = TextEditingController(text: widget.word.japanese);
    _exampleController = TextEditingController(text: widget.word.example);
    _selectedCategory = widget.word.category;
  }

  @override
  void dispose() {
    _japaneseController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.word.english,
                    style: AppTheme.display2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _japaneseController,
              decoration: const InputDecoration(
                labelText: '日本語訳',
                hintText: '日本語の意味を入力',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: '例文',
                hintText: '例文を入力',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WordCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
              ),
              items: WordCategory.values
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onDelete();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('削除'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final updatedWord = Word(
                        id: widget.word.id,
                        english: widget.word.english,
                        japanese: _japaneseController.text,
                        category: _selectedCategory,
                        example: _exampleController.text,
                        diaryEntryId: widget.word.diaryEntryId,
                        createdAt: widget.word.createdAt,
                        masteryLevel: widget.word.masteryLevel,
                        reviewCount: widget.word.reviewCount,
                        lastReviewedAt: widget.word.lastReviewedAt,
                      );
                      widget.onUpdate(updatedWord);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'noun':
        return '名詞';
      case 'verb':
        return '動詞';
      case 'adjective':
        return '形容詞';
      case 'adverb':
        return '副詞';
      default:
        return 'その他';
    }
  }
}

// Placeholder for WordStudySessionScreen
class WordStudySessionScreen extends StatelessWidget {
  final List<Word> words;
  final VoidCallback onComplete;

  const WordStudySessionScreen({
    super.key,
    required this.words,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('単語学習'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'この機能は開発中です',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '${words.length}個の単語を学習予定',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                onComplete();
                Navigator.pop(context);
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}