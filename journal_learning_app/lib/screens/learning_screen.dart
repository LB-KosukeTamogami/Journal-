import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import 'dart:ui';

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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Learning',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassContainer(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(4),
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
      body: Padding(
        padding: const EdgeInsets.only(top: 140),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCardList(_flashcards),
            _buildCardList(_flashcards.where((card) => !card['learned']).toList()),
            _buildCardList(_flashcards.where((card) => card['learned']).toList()),
          ],
        ),
      ),
      floatingActionButton: AnimatedGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: () {
          _startFlashcardSession();
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '学習を開始',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'カードがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
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
          delay: Duration(milliseconds: index * 100),
        ).slideX(begin: 0.2, end: 0);
      },
    );
  }

  void _showCardDetail(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
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
                        color: Colors.white.withOpacity(0.5),
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.white),
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
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '例文',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card['example'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['exampleJp'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: シャドウイング機能
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'シャドウイング',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          colors: card['learned'] 
                              ? [Colors.orange, Colors.red]
                              : [Colors.green, Colors.teal],
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                card['learned'] = !card['learned'];
                              });
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  card['learned'] ? Icons.close : Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  card['learned'] ? '未習得に戻す' : '習得済みにする',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startFlashcardSession() {
    final unlearned = _flashcards.where((card) => !card['learned']).toList();
    if (unlearned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('学習するカードがありません'),
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
      child: AnimatedGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getDifficultyColor(card['difficulty']).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getDifficultyColor(card['difficulty']).withOpacity(0.5),
                  width: 1,
                ),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['meaning'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: card['learned'] 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: card['learned'] 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: onToggleLearned,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    card['learned'] ? Icons.check_circle : Icons.circle_outlined,
                    color: card['learned'] ? Colors.green : Colors.white70,
                    size: 24,
                  ),
                ),
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
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}