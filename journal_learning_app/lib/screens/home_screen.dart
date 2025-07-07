import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_creation_screen.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../services/storage_service.dart';
import '../services/lily_service.dart';
import '../widgets/glass_container.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Mission> _missions = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  int _totalDays = 0;
  String _lilyMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final missions = await MissionService.getTodaysMissions();
      final analytics = await StorageService.getAnalyticsData();
      final recentEntries = await StorageService.getDiaryEntries();
      
      final completedMissions = missions.where((m) => m.isCompleted).length;
      final lilyMessage = LilyService.getContextualMessage(
        streakDays: analytics['currentStreak'] ?? 0,
        completedMissions: completedMissions,
        recentEntries: recentEntries.take(3).toList(),
      );
      
      setState(() {
        _missions = missions;
        _currentStreak = analytics['currentStreak'] ?? 0;
        _totalDays = analytics['totalEntries'] ?? 0;
        _lilyMessage = lilyMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMission(Mission mission) async {
    if (mission.isCompleted) return;
    
    final updatedMission = mission.copyWith(
      currentValue: mission.targetValue,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    
    await StorageService.saveMission(updatedMission);
    
    setState(() {
      final index = _missions.indexWhere((m) => m.id == mission.id);
      if (index != -1) {
        _missions[index] = updatedMission;
        // Lilyのお祝いメッセージを表示
        _lilyMessage = LilyService.getMissionCompleteMessage();
      }
    });
    
    // スナックバーでもお祝い
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LilyService.getMissionCompleteMessage()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Welcome Header
            GlassContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.waving_hand,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'おかえりなさい！',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '今日も素晴らしい学習の時間にしましょう ✨',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),

            // Lilyからのメッセージカード
            LiquidContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              colors: const [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFF6B73FF),
              ],
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.sentiment_very_satisfied,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lily より 💫',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lilyMessage.isNotEmpty 
                            ? _lilyMessage
                            : _currentStreak > 0 
                                ? '$_currentStreak日連続で頑張っています！' 
                                : '今日も一緒に英語を学びましょう！',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // 日記作成ボタン
            AnimatedGlassCard(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiaryCreationScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '新しい日記を書く',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 32),
            
            // 今日のミッション
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日のミッション',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'すべて見る',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ミッションリスト
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              ..._missions.map((mission) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _MissionCard(
                  mission: mission,
                  onToggle: () => _toggleMission(mission),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 300 + _missions.indexOf(mission) * 100),
              ).slideX(begin: 0.2, end: 0)),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onToggle;

  const _MissionCard({
    required this.mission,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool completed = mission.isCompleted;
    final String difficulty = _getDifficultyFromType(mission.type);
    final IconData icon = _getIconFromType(mission.type);
    
    return GlassContainer(
      opacity: completed ? 0.05 : 0.1,
      child: InkWell(
        onTap: completed ? null : onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: completed 
                    ? Colors.green.withOpacity(0.2)
                    : _getDifficultyColor(difficulty).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: completed 
                    ? Colors.green
                    : _getDifficultyColor(difficulty),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: completed ? Colors.grey[300] : Colors.white,
                        decoration: completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDifficultyColor(difficulty).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDifficultyColor(difficulty),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (completed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '+${mission.experiencePoints}XP',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (completed)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDifficultyFromType(MissionType type) {
    // 簡易的な実装 - 実際のアプリではより詳細な分類が必要
    switch (type) {
      case MissionType.dailyDiary:
        return '初級';
      case MissionType.wordLearning:
        return '中級';
      case MissionType.streak:
        return '上級';
      case MissionType.review:
        return '中級';
      case MissionType.conversation:
        return '上級';
    }
  }

  IconData _getIconFromType(MissionType type) {
    switch (type) {
      case MissionType.dailyDiary:
        return Icons.edit;
      case MissionType.wordLearning:
        return Icons.school;
      case MissionType.streak:
        return Icons.local_fire_department;
      case MissionType.review:
        return Icons.refresh;
      case MissionType.conversation:
        return Icons.chat;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '初級':
        return Colors.blue;
      case '中級':
        return Colors.orange;
      case '上級':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}