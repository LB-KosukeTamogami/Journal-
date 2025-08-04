import '../models/mission.dart';
import 'storage_service.dart';

class MissionService {
  // 本日のミッション生成
  static Future<List<Mission>> getTodaysMissions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 保存済みのミッションを取得
    final savedMissions = await StorageService.getMissions();
    
    // 本日のミッションのみフィルタリング
    final todaysMissions = savedMissions.where((mission) {
      final missionDate = DateTime(
        mission.createdAt.year,
        mission.createdAt.month,
        mission.createdAt.day,
      );
      return missionDate == today;
    }).toList();

    // 本日のミッションがない場合は新規生成
    if (todaysMissions.isEmpty) {
      final newMissions = await _generateDailyMissions();
      
      // 保存
      for (final mission in newMissions) {
        await StorageService.saveMission(mission);
      }
      
      return newMissions;
    }

    return todaysMissions;
  }

  // デイリーミッション生成
  static Future<List<Mission>> _generateDailyMissions() async {
    final missions = <Mission>[];
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    // 1. 日記投稿ミッション
    missions.add(Mission(
      title: '今日の日記を書こう',
      description: '今日の出来事を英語で記録しましょう',
      type: MissionType.dailyDiary,
      difficulty: MissionDifficulty.easy,
      targetValue: 1,
      experiencePoints: 50,
      expiresAt: tomorrow,
    ));

    // 2. 単語学習ミッション（ランダムで1つ選択）
    final wordMissions = [
      Mission(
        title: '新しい単語を3つ学ぼう',
        description: '日記から抽出した単語を覚えましょう',
        type: MissionType.wordLearning,
        difficulty: MissionDifficulty.easy,
        targetValue: 3,
        experiencePoints: 30,
        expiresAt: tomorrow,
      ),
      Mission(
        title: '単語復習マスター',
        description: '5つの単語を復習して定着させましょう',
        type: MissionType.wordLearning,
        difficulty: MissionDifficulty.medium,
        targetValue: 5,
        experiencePoints: 40,
        expiresAt: tomorrow,
      ),
    ];
    missions.add(wordMissions[DateTime.now().day % wordMissions.length]);

    // 3. 連続記録ミッション（条件付き）
    final diaryEntries = await StorageService.getDiaryEntries();
    final streak = await StorageService.getDiaryStreak();
    
    if (streak > 0) {
      missions.add(Mission(
        title: '${streak + 1}日連続を目指そう',
        description: '連続記録を更新しましょう',
        type: MissionType.streak,
        difficulty: MissionDifficulty.medium,
        targetValue: 1,
        experiencePoints: 60,
        expiresAt: tomorrow,
      ));
    } else {
      missions.add(Mission(
        title: '連続記録をスタート',
        description: '明日も日記を書いて2日連続を達成しよう',
        type: MissionType.streak,
        difficulty: MissionDifficulty.easy,
        targetValue: 1,
        experiencePoints: 40,
        expiresAt: tomorrow,
      ));
    }

    // 4. 会話練習ミッション（週2回）
    if (now.weekday == DateTime.tuesday || now.weekday == DateTime.friday) {
      missions.add(Mission(
        title: '会話ジャーナルに挑戦',
        description: 'Acoと英語で会話してみましょう',
        type: MissionType.conversation,
        difficulty: MissionDifficulty.medium,
        targetValue: 1,
        experiencePoints: 70,
        expiresAt: tomorrow,
      ));
    }

    return missions;
  }

  // ミッション完了処理
  static Future<void> completeMission(String missionId) async {
    final missions = await StorageService.getMissions();
    final missionIndex = missions.indexWhere((m) => m.id == missionId);
    
    if (missionIndex != -1) {
      final mission = missions[missionIndex];
      final completedMission = mission.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        currentValue: mission.targetValue,
      );
      
      await StorageService.saveMission(completedMission);
    }
  }

  // ミッション進捗更新
  static Future<void> updateMissionProgress(
    MissionType type, {
    int incrementBy = 1,
  }) async {
    final missions = await getTodaysMissions();
    
    for (final mission in missions) {
      if (mission.type == type && !mission.isCompleted) {
        final newValue = (mission.currentValue + incrementBy)
            .clamp(0, mission.targetValue);
        
        final updatedMission = mission.copyWith(
          currentValue: newValue,
          isCompleted: newValue >= mission.targetValue,
          completedAt: newValue >= mission.targetValue ? DateTime.now() : null,
        );
        
        await StorageService.saveMission(updatedMission);
      }
    }
  }

  // 特定タイプのミッション取得
  static Future<Mission?> getTodaysMissionByType(MissionType type) async {
    final missions = await getTodaysMissions();
    
    try {
      return missions.firstWhere((m) => m.type == type);
    } catch (e) {
      return null;
    }
  }

  // ミッション達成率計算
  static Future<double> getTodaysCompletionRate() async {
    final missions = await getTodaysMissions();
    if (missions.isEmpty) return 0.0;
    
    final completedCount = missions.where((m) => m.isCompleted).length;
    return completedCount / missions.length;
  }
}