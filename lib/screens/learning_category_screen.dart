import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import 'learning_screen.dart';

class LearningCategoryScreen extends StatefulWidget {
  const LearningCategoryScreen({super.key});

  @override
  State<LearningCategoryScreen> createState() => _LearningCategoryScreenState();
}

class _LearningCategoryScreenState extends State<LearningCategoryScreen> {
  List<Word> _allWords = [];
  Map<WordCategory, int> _categoryWordCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final words = await StorageService.getWords();
      
      // カテゴリ別の単語数をカウント
      final counts = <WordCategory, int>{};
      for (final category in WordCategory.values) {
        counts[category] = 0;
      }
      
      for (final word in words) {
        counts[word.category] = (counts[word.category] ?? 0) + 1;
      }
      
      setState(() {
        _allWords = words;
        _categoryWordCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLearning({WordCategory? selectedCategory}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningScreen(
          initialCategory: selectedCategory,
        ),
      ),
    ).then((_) {
      // 画面が戻ってきたらデータを再読み込み
      _loadData();
    });
  }

  Color _getCategoryColor(WordCategory category) {
    switch (category) {
      case WordCategory.noun:
        return Colors.blue;
      case WordCategory.verb:
        return Colors.red;
      case WordCategory.adjective:
        return Colors.green;
      case WordCategory.adverb:
        return Colors.orange;
      case WordCategory.pronoun:
        return Colors.purple;
      case WordCategory.preposition:
        return Colors.teal;
      case WordCategory.conjunction:
        return Colors.pink;
      case WordCategory.interjection:
        return Colors.amber;
      case WordCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(WordCategory category) {
    switch (category) {
      case WordCategory.noun:
        return Icons.label;
      case WordCategory.verb:
        return Icons.directions_run;
      case WordCategory.adjective:
        return Icons.palette;
      case WordCategory.adverb:
        return Icons.speed;
      case WordCategory.pronoun:
        return Icons.person;
      case WordCategory.preposition:
        return Icons.location_on;
      case WordCategory.conjunction:
        return Icons.link;
      case WordCategory.interjection:
        return Icons.priority_high;
      case WordCategory.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('学習', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // すべてボタン
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _navigateToLearning(),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundPrimary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.all_inclusive,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'すべて',
                                      style: AppTheme.headline3.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_allWords.length}個の単語',
                                      style: AppTheme.body2.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  // カテゴリ別ボタン
                  ...WordCategory.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final count = _categoryWordCounts[category] ?? 0;
                    final color = _getCategoryColor(category);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: count > 0 ? () => _navigateToLearning(selectedCategory: category) : null,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundPrimary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: count > 0 
                                    ? color.withOpacity(0.3)
                                    : AppTheme.borderColor,
                                width: count > 0 ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(count > 0 ? 0.1 : 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: count > 0 ? color : AppTheme.textSecondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.displayName,
                                        style: AppTheme.headline3.copyWith(
                                          color: count > 0 ? color : AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${count}個の単語',
                                        style: AppTheme.body2.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: count > 0 ? color : AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: Duration(milliseconds: 100 + index * 50))
                      .slideY(begin: 0.2, end: 0);
                  }).toList(),
                ],
              ),
            ),
    );
  }
}