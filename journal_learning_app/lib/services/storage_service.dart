import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/user_profile.dart';
import '../models/mission.dart';
import '../models/flashcard.dart';

class StorageService {
  static const String _diaryEntriesKey = 'diary_entries';
  static const String _userProfileKey = 'user_profile';
  static const String _missionsKey = 'missions';
  static const String _flashcardsKey = 'flashcards';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  static Future<List<DiaryEntry>> getDiaryEntries() async {
    final jsonString = prefs.getString(_diaryEntriesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
  }

  static Future<void> saveDiaryEntry(DiaryEntry entry) async {
    final entries = await getDiaryEntries();
    
    final existingIndex = entries.indexWhere((e) => e.id == entry.id);
    if (existingIndex != -1) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
    
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryEntriesKey, jsonString);
  }

  static Future<void> deleteDiaryEntry(String id) async {
    final entries = await getDiaryEntries();
    entries.removeWhere((e) => e.id == id);
    
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryEntriesKey, jsonString);
  }

  static Future<UserProfile?> getUserProfile() async {
    final jsonString = prefs.getString(_userProfileKey);
    if (jsonString == null) return null;

    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserProfile.fromJson(json);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final jsonString = json.encode(profile.toJson());
    await prefs.setString(_userProfileKey, jsonString);
  }

  static Future<List<Mission>> getMissions() async {
    final jsonString = prefs.getString(_missionsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Mission.fromJson(json)).toList();
  }

  static Future<void> saveMission(Mission mission) async {
    final missions = await getMissions();
    
    final existingIndex = missions.indexWhere((m) => m.id == mission.id);
    if (existingIndex != -1) {
      missions[existingIndex] = mission;
    } else {
      missions.add(mission);
    }
    
    final jsonString = json.encode(missions.map((m) => m.toJson()).toList());
    await prefs.setString(_missionsKey, jsonString);
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final jsonString = json.encode(missions.map((m) => m.toJson()).toList());
    await prefs.setString(_missionsKey, jsonString);
  }

  static Future<List<Flashcard>> getFlashcards() async {
    final jsonString = prefs.getString(_flashcardsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Flashcard.fromJson(json)).toList();
  }

  static Future<void> saveFlashcard(Flashcard flashcard) async {
    final flashcards = await getFlashcards();
    
    final existingIndex = flashcards.indexWhere((f) => f.id == flashcard.id);
    if (existingIndex != -1) {
      flashcards[existingIndex] = flashcard;
    } else {
      flashcards.add(flashcard);
    }
    
    final jsonString = json.encode(flashcards.map((f) => f.toJson()).toList());
    await prefs.setString(_flashcardsKey, jsonString);
  }

  static Future<void> saveFlashcards(List<Flashcard> flashcards) async {
    final jsonString = json.encode(flashcards.map((f) => f.toJson()).toList());
    await prefs.setString(_flashcardsKey, jsonString);
  }

  static Future<void> clearAll() async {
    await prefs.clear();
  }

  static Future<int> getDiaryStreak() async {
    final entries = await getDiaryEntries();
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      final checkDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      if (entryDate == checkDate || entryDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  static Future<Map<String, int>> getAnalyticsData() async {
    final entries = await getDiaryEntries();
    final missions = await getMissions();
    final flashcards = await getFlashcards();
    
    final totalWords = entries.fold<int>(0, (sum, entry) => sum + entry.wordCount);
    final completedMissions = missions.where((m) => m.isCompleted).length;
    final learnedWords = flashcards.where((f) => f.isLearned).length;
    final streak = await getDiaryStreak();
    
    return {
      'totalEntries': entries.length,
      'totalWords': totalWords,
      'completedMissions': completedMissions,
      'learnedWords': learnedWords,
      'currentStreak': streak,
    };
  }
}