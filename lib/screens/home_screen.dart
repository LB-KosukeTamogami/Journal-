import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_creation_screen.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../services/storage_service.dart';
import '../services/aco_service.dart';
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
  String _acoMessage = '';
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
      final acoMessage = AcoService.getContextualMessage(
        streakDays: analytics['currentStreak'] ?? 0,
        completedMissions: completedMissions,
        recentEntries: recentEntries.take(3).toList(),
      );
      
      setState(() {
        _missions = missions;
        _currentStreak = analytics['currentStreak'] ?? 0;
        _totalDays = analytics['totalLearningDays'] ?? 0;
        _acoMessage = acoMessage;
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
        _acoMessage = AcoService.getMissionCompleteMessage();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AcoService.getMissionCompleteMessage()),
        backgroundColor: Theme.of(context).colorScheme.secondary,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Theme.of(context).primaryColor,
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
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_today.month}月${_today.day}日 ${_getDayOfWeek()}曜日',
                        style: Theme.of(context).textTheme.bodyMedium,
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

              // Acoからのメッセージ
              if (_acoMessage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: _buildAcoMessageCard(),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
                ),

              // ミッションセクション
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    '今日のミッション',
                    style: Theme.of(context).textTheme.displaySmall,
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
                        color: Theme.of(context).primaryColor,
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
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '今日のミッションはありません',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                  Theme.of(context).colorScheme.error.withOpacity(0.8),
                  Theme.of(context).brightness == Brightness.light 
                    ? AppTheme.lightColors.warning
                    : AppTheme.darkColors.warning,
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_currentStreak',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '日',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalDays日',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      backgroundColor: Theme.of(context).primaryColor,
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

  Widget _buildAcoMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkColors.surface 
              : AppTheme.lightColors.surface,
            Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkColors.surfaceVariant 
              : AppTheme.lightColors.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkColors.surface
                    : AppTheme.lightColors.surface,
                  Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkColors.surfaceVariant
                    : AppTheme.lightColors.surfaceVariant,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '🐿',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aco からのメッセージ',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _acoMessage,
                  style: AppTheme.body2.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
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

  const _MissionCard({
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final bool completed = mission.isCompleted;
    final IconData icon = _getIconFromType(mission.type);
    final Color color = _getColorFromType(mission.type, context);
    
    return AppCard(
      onTap: null, // タップ不可
      backgroundColor: completed ? (Theme.of(context).brightness == Brightness.light ? AppTheme.lightColors.surfaceVariant : AppTheme.darkColors.surfaceVariant) : Theme.of(context).cardColor,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completed 
                ? (Theme.of(context).brightness == Brightness.light 
                  ? AppTheme.lightColors.success.withOpacity(0.1)
                  : AppTheme.darkColors.success.withOpacity(0.1))
                : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_circle : icon,
              color: completed 
                ? (Theme.of(context).brightness == Brightness.light 
                  ? AppTheme.lightColors.success
                  : AppTheme.darkColors.success)
                : color,
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
                    color: completed 
                      ? Theme.of(context).textTheme.bodySmall?.color 
                      : Theme.of(context).textTheme.bodyLarge?.color,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: AppTheme.body2.copyWith(
                    color: completed 
                      ? Theme.of(context).textTheme.bodySmall?.color 
                      : Theme.of(context).textTheme.bodyMedium?.color,
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
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${mission.experiencePoints}XP',
                style: AppTheme.caption.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
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

  Color _getColorFromType(MissionType type, BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.light ? AppTheme.lightColors : AppTheme.darkColors;
    
    switch (type) {
      case MissionType.dailyDiary:
        return colors.primary;
      case MissionType.wordLearning:
        return colors.info;
      case MissionType.streak:
        return colors.warning;
      case MissionType.review:
        return colors.success;
      case MissionType.conversation:
        return colors.info;
    }
  }
}