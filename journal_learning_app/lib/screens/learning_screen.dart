import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Learning'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: '学習中'),
            Tab(text: '習得済み'),
          ],
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "learning_fab",
        onPressed: () {
          _startFlashcardSession();
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('学習を開始'),
        backgroundColor: Theme.of(context).primaryColor,
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'カードがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey[300],
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
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    // TODO: TTS実装
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card['meaning'],
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '例文',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card['example'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['exampleJp'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                      // TODO: シャドウイング機能
                    },
                    icon: const Icon(Icons.mic),
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
                    icon: Icon(
                      card['learned'] ? Icons.close : Icons.check,
                    ),
                    label: Text(
                      card['learned'] ? '未習得に戻す' : '習得済みにする',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card['meaning'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  card['learned'] ? Icons.check_circle : Icons.circle_outlined,
                  color: card['learned'] ? Colors.green : Colors.grey[400],
                ),
                onPressed: onToggleLearned,
              ),
            ],
          ),
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