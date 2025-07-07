import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // サンプルの暗記カードデータ
  final List<Map<String, dynamic>> _flashcards = [
    {
      'id': '1',
      'word': 'accomplish',
      'meaning': '達成する、成し遂げる',
      'example': 'I want to accomplish my goals this year.',
      'exampleJp': '今年は目標を達成したいです。',
      'learned': false,
      'difficulty': 'medium',
    },
    {
      'id': '2',
      'word': 'grateful',
      'meaning': '感謝している',
      'example': 'I am grateful for your help.',
      'exampleJp': 'あなたの助けに感謝しています。',
      'learned': false,
      'difficulty': 'easy',
    },
    {
      'id': '3',
      'word': 'persevere',
      'meaning': '忍耐する、頑張り抜く',
      'example': 'We must persevere through difficult times.',
      'exampleJp': '困難な時期を乗り越えなければなりません。',
      'learned': true,
      'difficulty': 'hard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text('Learning', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
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
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                tabs: const [
                  Tab(text: 'すべて'),
                  Tab(text: '学習中'),
                  Tab(text: '習得済み'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardList(_flashcards),
          _buildCardList(_flashcards.where((card) => !card['learned']).toList()),
          _buildCardList(_flashcards.where((card) => card['learned']).toList()),
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
          backgroundColor: AppTheme.primaryBlue,
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: Text('学習を開始', style: AppTheme.button),
        ),
      ),
    );
  }

  Widget _buildCardList(List<Map<String, dynamic>> cards) {
    if (cards.isEmpty) {
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _FlashcardItem(
          card: card,
          onTap: () => _showCardDetail(card),
          onToggleLearned: () {
            setState(() {
              card['learned'] = !card['learned'];
            });
          },
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 50),
          duration: 300.ms,
        ).slideX(begin: 0.1, end: 0);
      },
    );
  }

  void _showCardDetail(Map<String, dynamic> card) {
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
                  card['word'],
                  style: AppTheme.headline2,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.volume_up, color: AppTheme.primaryBlue),
                    onPressed: () {
                      // TODO: TTS実装
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card['meaning'],
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
                  Text(
                    card['example'],
                    style: AppTheme.body1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['exampleJp'],
                    style: AppTheme.body2,
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
                      // TODO: シャドウイング機能
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('シャドウイング'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        card['learned'] = !card['learned'];
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: card['learned'] 
                          ? AppTheme.warning
                          : AppTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      card['learned'] ? Icons.close : Icons.check,
                      size: 20,
                    ),
                    label: Text(
                      card['learned'] ? '未習得に戻す' : '習得済みにする',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _startFlashcardSession() {
    final unlearned = _flashcards.where((card) => !card['learned']).toList();
    if (unlearned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('学習するカードがありません', style: AppTheme.body2.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.textSecondary,
        ),
      );
      return;
    }
    // TODO: フラッシュカード学習画面への遷移
  }
}

class _FlashcardItem extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onTap;
  final VoidCallback onToggleLearned;

  const _FlashcardItem({
    required this.card,
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
                color: _getDifficultyColor(card['difficulty']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  card['word'][0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(card['difficulty']),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['word'],
                    style: AppTheme.body1.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['meaning'],
                    style: AppTheme.body2,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleLearned,
              icon: Icon(
                card['learned'] ? Icons.check_circle : Icons.circle_outlined,
                color: card['learned'] ? AppTheme.success : AppTheme.textTertiary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return AppTheme.error;
      default:
        return AppTheme.textTertiary;
    }
  }
}