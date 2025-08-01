import 'dart:math';
import '../models/mission.dart';
import '../models/diary_entry.dart';

class AcoService {
  static const List<String> _greetingMessages = [
    'こんにちは！今日も一緒に英語を学びましょう！✨',
    'お疲れさまです！今日はどんな一日でしたか？😊',
    'こんばんは！今日の出来事を英語で書いてみませんか？',
    'Hello! Let\'s practice English together today! 🌟',
    'おかえりなさい！今日も頑張りましたね💪',
    '今日も新しいことを学ぶ準備はできていますか？🎯',
  ];

  static const List<String> _encouragementMessages = [
    'すごいですね！継続は力なりです！🎉',
    'Great job! あなたの努力が実を結んでいますね！',
    '素晴らしい進歩です！このまま頑張りましょう！',
    'Amazing! 毎日少しずつでも続けることが大切ですね😊',
    'Well done! 英語力がどんどん向上していますよ！',
    'Excellent! あなたの熱意に感動しています！💖',
    'Perfect! 今日も一歩前進しましたね！🚀',
    'Wonderful! 継続している自分を誇りに思ってください！',
  ];

  static const List<String> _missionCompleteMessages = [
    'ミッション完了おめでとうございます！🎊',
    'Great! また一つ目標を達成しましたね！',
    'Fantastic! この調子で頑張りましょう！',
    'Well done! あなたの努力が報われましたね！',
    'Amazing! 今日のミッションクリアです！✨',
    'Perfect! すばらしい集中力でした！',
    'Excellent work! 次のチャレンジも楽しみですね！',
  ];

  static const List<String> _streakMessages = [
    'すごい！{days}日連続です！継続の力を感じますね！🔥',
    'Amazing! {days}日間毎日頑張っていますね！',
    'Fantastic! {days}日連続記録更新中です！💪',
    'Great streak! {days}日間の努力が素晴らしいです！',
    'Wonderful! {days}日連続、本当にすごいですよ！🌟',
    'Incredible! {days}日間の継続、尊敬します！',
  ];

  static const List<String> _motivationalMessages = [
    '今日が新しいスタートです！一緒に頑張りましょう！',
    '小さな一歩でも大きな進歩につながります🌱',
    'Every day is a new opportunity to improve!',
    '完璧を目指さず、進歩を楽しみましょう😊',
    '間違いを恐れず、チャレンジし続けてくださいね！',
    'You\'re doing great! Keep up the good work!',
    '学習は旅路です。楽しみながら進みましょう🎯',
    '今日のあなたは昨日のあなたより成長しています！',
  ];

  static const List<String> _tipMessages = [
    '💡 Tip: 短い文でも毎日書くことが大切です！',
    '💡 Tip: 新しい単語を1つずつ覚えていきましょう！',
    '💡 Tip: 感情を英語で表現してみると表現力がアップします！',
    '💡 Tip: 過去形と現在形を使い分けてみてください！',
    '💡 Tip: 日常の出来事を英語で考える習慣をつけましょう！',
    '💡 Tip: 辞書を使わずに知っている単語で表現してみてください！',
    '💡 Tip: 声に出して読むと記憶に残りやすくなります！',
  ];

  /// 時間帯に応じた挨拶メッセージを取得
  static String getGreetingMessage() {
    final random = Random();
    return _greetingMessages[random.nextInt(_greetingMessages.length)];
  }

  /// ミッション完了時のお祝いメッセージ
  static String getMissionCompleteMessage() {
    final random = Random();
    return _missionCompleteMessages[random.nextInt(_missionCompleteMessages.length)];
  }

  /// 継続日数に応じた応援メッセージ
  static String getStreakMessage(int streakDays) {
    if (streakDays <= 0) return getMotivationalMessage();
    
    final random = Random();
    final template = _streakMessages[random.nextInt(_streakMessages.length)];
    return template.replaceAll('{days}', streakDays.toString());
  }

  /// 一般的な励ましメッセージ
  static String getEncouragementMessage() {
    final random = Random();
    return _encouragementMessages[random.nextInt(_encouragementMessages.length)];
  }

  /// やる気を引き出すメッセージ
  static String getMotivationalMessage() {
    final random = Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  /// 学習のコツやアドバイス
  static String getTipMessage() {
    final random = Random();
    return _tipMessages[random.nextInt(_tipMessages.length)];
  }

  /// 状況に応じたメッセージを自動選択
  static String getContextualMessage({
    required int streakDays,
    required int completedMissions, 
    required List<DiaryEntry> recentEntries,
    bool isFirstVisit = false,
    bool justCompletedMission = false,
  }) {
    if (isFirstVisit) {
      return 'はじめまして！私はAcoです😊 一緒に英語学習を楽しみましょう！';
    }

    if (justCompletedMission) {
      return getMissionCompleteMessage();
    }

    if (streakDays >= 7) {
      return getStreakMessage(streakDays);
    }

    if (streakDays >= 3) {
      final random = Random();
      return random.nextBool() 
          ? getStreakMessage(streakDays)
          : getEncouragementMessage();
    }

    if (recentEntries.isNotEmpty) {
      return getEncouragementMessage();
    }

    if (completedMissions > 0) {
      return getEncouragementMessage();
    }

    // デフォルトは挨拶メッセージ
    return getGreetingMessage();
  }

  /// 日記の内容に基づいたフィードバック
  static String getDiaryFeedback(DiaryEntry entry) {
    final wordCount = entry.wordCount;
    final content = entry.content.toLowerCase();
    
    List<String> feedback = [];

    // 文字数に基づくフィードバック
    if (wordCount >= 100) {
      feedback.add('長文での表現、素晴らしいです！📝');
    } else if (wordCount >= 50) {
      feedback.add('Good length! ちょうど良い長さですね！');
    } else if (wordCount >= 20) {
      feedback.add('Nice work! 簡潔で分かりやすいです😊');
    }

    // 感情表現の検出
    final emotionWords = ['happy', 'sad', 'excited', 'tired', 'angry', 'surprised', 'worried'];
    final foundEmotions = emotionWords.where((word) => content.contains(word)).toList();
    
    if (foundEmotions.isNotEmpty) {
      feedback.add('感情表現が豊かですね！✨');
    }

    // 過去形の使用
    final pastTenseWords = ['was', 'were', 'went', 'did', 'had', 'ate', 'came', 'saw'];
    final foundPastTense = pastTenseWords.where((word) => content.contains(word)).toList();
    
    if (foundPastTense.isNotEmpty) {
      feedback.add('過去形を使って上手に表現できていますね！');
    }

    if (feedback.isEmpty) {
      feedback.add('今日も日記を書いてくれてありがとう！🌟');
    }

    final random = Random();
    return feedback[random.nextInt(feedback.length)];
  }

  /// 時間帯に応じたメッセージの調整
  static String getTimeBasedMessage() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'おはようございます！今日も一緒に頑張りましょう！🌅';
    } else if (hour >= 12 && hour < 17) {
      return 'お疲れさまです！午後の学習時間ですね😊';
    } else if (hour >= 17 && hour < 22) {
      return 'こんばんは！今日の振り返りをしてみませんか？🌙';
    } else {
      return '夜遅くまでお疲れさまです！無理をしないでくださいね💤';
    }
  }

  /// ランダムな豆知識やファクト
  static String getRandomFact() {
    const facts = [
      '🌍 英語は世界で最も学習されている言語の一つです！',
      '📚 1日15分の学習でも1年で90時間以上になります！',
      '🧠 新しい言語を学ぶと脳の認知能力が向上します！',
      '✍️ 書くことで記憶が定着しやすくなります！',
      '🗣️ 英語の単語は約100万語以上あると言われています！',
      '🎯 継続は最も効果的な学習方法の一つです！',
      '💪 間違いを恐れずにチャレンジすることが成長の鍵です！',
    ];

    final random = Random();
    return facts[random.nextInt(facts.length)];
  }
}