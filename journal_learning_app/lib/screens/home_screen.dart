import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_creation_screen.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../services/storage_service.dart';
import '../services/lily_service.dart';
import '../theme/app_theme.dart';

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
  DateTime _today = DateTime.now();

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
        _lilyMessage = LilyService.getMissionCompleteMessage();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LilyService.getMissionCompleteMessage()),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTheme.headline1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_today.month}月${_today.day}日 ${_getDayOfWeek()}曜日',
                        style: AppTheme.body2,
                      ),
                    ],
                  ),
                ),
              ),

              // 連続記録カード
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: _buildStreakCard(),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
              ),

              // 今日の日記作成ボタン
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCreateDiaryCard(),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
              ),

              // Lilyからのメッセージ
              if (_lilyMessage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: _buildLilyMessageCard(),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
                ),

              // ミッションセクション
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    '今日のミッション',
                    style: AppTheme.headline3,
                  ),
                ),
              ),

              // ミッションリスト
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                )
              else if (_missions.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '今日のミッションはありません',
                            style: AppTheme.body2,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mission = _missions[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: _MissionCard(
                          mission: mission,
                          onToggle: () => _toggleMission(mission),
                        ),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 300 + index * 50),
                        duration: 300.ms,
                      ).slideX(begin: -0.1, end: 0);
                    },
                    childCount: _missions.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlueLight,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '連続記録',
                  style: AppTheme.body2,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_currentStreak',
                      style: AppTheme.headline2.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '日',
                      style: AppTheme.body2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '総学習日数',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalDays日',
                style: AppTheme.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateDiaryCard() {
    return AppCard(
      backgroundColor: AppTheme.primaryBlue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DiaryCreationScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日の日記を書く',
                  style: AppTheme.body1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '英語で今日の出来事を記録しましょう',
                  style: AppTheme.body2.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.6),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildLilyMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates,
              color: AppTheme.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lily からのアドバイス',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lilyMessage,
                  style: AppTheme.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = _today.hour;
    if (hour < 5) return 'こんばんは';
    if (hour < 10) return 'おはようございます';
    if (hour < 17) return 'こんにちは';
    return 'こんばんは';
  }

  String _getDayOfWeek() {
    const days = ['日', '月', '火', '水', '木', '金', '土'];
    return days[_today.weekday % 7];
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
    final IconData icon = _getIconFromType(mission.type);
    final Color color = _getColorFromType(mission.type);
    
    return AppCard(
      onTap: completed ? null : onToggle,
      backgroundColor: completed ? AppTheme.backgroundTertiary : AppTheme.backgroundPrimary,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completed 
                ? AppTheme.success.withOpacity(0.1)
                : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_circle : icon,
              color: completed ? AppTheme.success : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: completed ? AppTheme.textTertiary : AppTheme.textPrimary,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: AppTheme.body2.copyWith(
                    color: completed ? AppTheme.textTertiary : AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!completed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${mission.experiencePoints}XP',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconFromType(MissionType type) {
    switch (type) {
      case MissionType.dailyDiary:
        return Icons.edit_note;
      case MissionType.wordLearning:
        return Icons.translate;
      case MissionType.streak:
        return Icons.local_fire_department;
      case MissionType.review:
        return Icons.refresh;
      case MissionType.conversation:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getColorFromType(MissionType type) {
    switch (type) {
      case MissionType.dailyDiary:
        return AppTheme.primaryBlue;
      case MissionType.wordLearning:
        return AppTheme.info;
      case MissionType.streak:
        return AppTheme.warning;
      case MissionType.review:
        return AppTheme.success;
      case MissionType.conversation:
        return const Color(0xFF8B5CF6);
    }
  }
}