import 'dart:math';
import '../models/mission.dart';
import '../models/diary_entry.dart';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';

class MissionService {
  static const List<Map<String, dynamic>> _missionTemplates = [
    // 初級ミッション
    {
      'title': '今日の出来事を3文で書く',
      'description': '今日あった出来事を英語で3文以上書いてみましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'beginner',
      'targetValue': 3,
      'experiencePoints': 10,
    },
    {
      'title': '感情を表す単語を使う',
      'description': 'happy, sad, excited などの感情を表す単語を使って書きましょう',
      'type': MissionType.wordLearning,
      'difficulty': 'beginner',
      'targetValue': 1,
      'experiencePoints': 15,
    },
    {
      'title': '今日学んだことを書く',
      'description': '今日学んだことや気づいたことを英語で書いてみましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'beginner',
      'targetValue': 1,
      'experiencePoints': 10,
    },
    
    // 中級ミッション
    {
      'title': '過去形を使って昨日を振り返る',
      'description': '昨日の出来事を過去形を使って詳しく書いてみましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'intermediate',
      'targetValue': 5,
      'experiencePoints': 20,
    },
    {
      'title': '新しい単語を5つ使う',
      'description': '今日覚えた新しい単語を5つ使って日記を書きましょう',
      'type': MissionType.wordLearning,
      'difficulty': 'intermediate',
      'targetValue': 5,
      'experiencePoints': 25,
    },
    {
      'title': '会話形式で書く',
      'description': '今日の会話を思い出して、会話形式で書いてみましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'intermediate',
      'targetValue': 1,
      'experiencePoints': 20,
    },
    
    // 上級ミッション
    {
      'title': '複雑な文構造を使う',
      'description': '関係代名詞や接続詞を使って複雑な文を作ってみましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'advanced',
      'targetValue': 3,
      'experiencePoints': 30,
    },
    {
      'title': '抽象的な概念について書く',
      'description': '愛、友情、成功などの抽象的な概念について考えを書きましょう',
      'type': MissionType.dailyDiary,
      'difficulty': 'advanced',
      'targetValue': 1,
      'experiencePoints': 35,
    },
    {
      'title': '3日連続で日記を書く',
      'description': '3日間連続で日記を書いて習慣を作りましょう',
      'type': MissionType.streak,
      'difficulty': 'advanced',
      'targetValue': 3,
      'experiencePoints': 50,
    },
  ];

  static Future<List<Mission>> generateDailyMissions({int count = 3}) async {
    final random = Random();
    final now = DateTime.now();
    final missions = <Mission>[];
    
    // 難易度別にミッションを選択
    final beginnerMissions = _missionTemplates.where((m) => m['difficulty'] == 'beginner').toList();
    final intermediateMissions = _missionTemplates.where((m) => m['difficulty'] == 'intermediate').toList();
    final advancedMissions = _missionTemplates.where((m) => m['difficulty'] == 'advanced').toList();
    
    // 初級から1つ、中級から1つ、上級から1つ選択
    final selectedTemplates = [
      beginnerMissions[random.nextInt(beginnerMissions.length)],
      intermediateMissions[random.nextInt(intermediateMissions.length)],
      advancedMissions[random.nextInt(advancedMissions.length)],
    ];
    
    for (int i = 0; i < count && i < selectedTemplates.length; i++) {
      final template = selectedTemplates[i];
      
      final mission = Mission(
        id: const Uuid().v4(),
        title: template['title'],
        description: template['description'],
        type: template['type'],
        targetValue: template['targetValue'],
        createdAt: now,
        experiencePoints: template['experiencePoints'],
        isDaily: true,
        resetDate: DateTime(now.year, now.month, now.day + 1),
      );
      
      missions.add(mission);
    }
    
    return missions;
  }

  static Future<void> checkMissionProgress(Mission mission, DiaryEntry? entry) async {
    if (mission.isCompleted) return;
    
    int progress = mission.currentValue;
    
    switch (mission.type) {
      case MissionType.dailyDiary:
        if (entry != null) {
          if (mission.title.contains('3文')) {
            // 文の数をカウント（簡易的に'.'で区切る）
            final sentences = entry.content.split('.').where((s) => s.trim().isNotEmpty).length;
            progress = sentences;
          } else if (mission.title.contains('過去形')) {
            // 過去形の単語をカウント（簡易的）
            final pastTenseWords = ['was', 'were', 'went', 'did', 'had', 'ate', 'came', 'saw'];
            int pastTenseCount = 0;
            for (final word in pastTenseWords) {
              pastTenseCount += word.allMatches(entry.content.toLowerCase()).length;
            }
            progress = pastTenseCount;
          } else {
            progress = 1; // 日記を書いたら完了
          }
        }
        break;
        
      case MissionType.wordLearning:
        if (entry != null) {
          if (mission.title.contains('感情')) {
            // 感情を表す単語をカウント
            final emotionWords = ['happy', 'sad', 'excited', 'angry', 'surprised', 'worried', 'pleased'];
            int emotionCount = 0;
            for (final word in emotionWords) {
              emotionCount += word.allMatches(entry.content.toLowerCase()).length;
            }
            progress = emotionCount;
          } else if (mission.title.contains('新しい単語')) {
            progress = entry.newWords.length;
          }
        }
        break;
        
      case MissionType.streak:
        // ストリーク系は別途実装
        final streak = await StorageService.getDiaryStreak();
        progress = streak;
        break;
        
      case MissionType.review:
      case MissionType.conversation:
        // 将来実装
        break;
    }
    
    final updatedMission = mission.copyWith(
      currentValue: progress,
      isCompleted: progress >= mission.targetValue,
      completedAt: progress >= mission.targetValue ? DateTime.now() : null,
    );
    
    await StorageService.saveMission(updatedMission);
  }

  static Future<List<Mission>> getTodaysMissions() async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // 保存されたミッションを取得
    final allMissions = await StorageService.getMissions();
    final todaysMissions = allMissions.where((mission) {
      if (!mission.isDaily) return false;
      
      final missionDate = mission.createdAt;
      final missionDateString = '${missionDate.year}-${missionDate.month.toString().padLeft(2, '0')}-${missionDate.day.toString().padLeft(2, '0')}';
      
      return missionDateString == todayString;
    }).toList();
    
    // 今日のミッションがなければ生成
    if (todaysMissions.isEmpty) {
      final newMissions = await generateDailyMissions();
      for (final mission in newMissions) {
        await StorageService.saveMission(mission);
      }
      return newMissions;
    }
    
    return todaysMissions;
  }

  static Future<void> resetDailyMissions() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    final allMissions = await StorageService.getMissions();
    final yesterdaysMissions = allMissions.where((mission) {
      if (!mission.isDaily) return false;
      
      final missionDate = mission.createdAt;
      return missionDate.year == yesterday.year &&
             missionDate.month == yesterday.month &&
             missionDate.day == yesterday.day;
    }).toList();
    
    // 昨日のミッションを削除（オプション）
    // 実際のアプリでは履歴として残すかもしれません
    
    // 新しいミッションを生成
    await getTodaysMissions();
  }

  static Map<String, dynamic> getMissionProgress(List<Mission> missions) {
    final total = missions.length;
    final completed = missions.where((m) => m.isCompleted).length;
    final totalExp = missions.fold<int>(0, (sum, m) => sum + (m.isCompleted ? m.experiencePoints : 0));
    
    return {
      'total': total,
      'completed': completed,
      'progress': total > 0 ? completed / total : 0.0,
      'experienceEarned': totalExp,
    };
  }
}