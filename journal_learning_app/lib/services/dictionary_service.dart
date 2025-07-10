import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryEntry {
  final String word;
  final String? phonetics;
  final String? audioUrl;
  final String partOfSpeech;
  final String definition;
  final List<String>? synonyms;
  final List<String>? examples;

  DictionaryEntry({
    required this.word,
    this.phonetics,
    this.audioUrl,
    required this.partOfSpeech,
    required this.definition,
    this.synonyms,
    this.examples,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    // 最初の発音情報を取得
    String? phonetics;
    String? audioUrl;
    if (json['phonetics'] != null && json['phonetics'].isNotEmpty) {
      final phoneticsList = json['phonetics'] as List;
      for (var phonetic in phoneticsList) {
        if (phonetic['text'] != null) {
          phonetics = phonetic['text'];
        }
        if (phonetic['audio'] != null && phonetic['audio'].toString().isNotEmpty) {
          audioUrl = phonetic['audio'];
        }
        if (phonetics != null && audioUrl != null) break;
      }
    }

    // 最初の意味と定義を取得
    String partOfSpeech = 'unknown';
    String definition = 'No definition available';
    List<String> synonyms = [];
    List<String> examples = [];

    if (json['meanings'] != null && json['meanings'].isNotEmpty) {
      final meanings = json['meanings'] as List;
      if (meanings.isNotEmpty) {
        final firstMeaning = meanings[0];
        partOfSpeech = firstMeaning['partOfSpeech'] ?? 'unknown';
        
        if (firstMeaning['definitions'] != null && firstMeaning['definitions'].isNotEmpty) {
          final definitions = firstMeaning['definitions'] as List;
          definition = definitions[0]['definition'] ?? 'No definition available';
          
          // 例文を取得
          if (definitions[0]['example'] != null) {
            examples.add(definitions[0]['example']);
          }
        }
        
        // 同義語を取得
        if (firstMeaning['synonyms'] != null) {
          synonyms = List<String>.from(firstMeaning['synonyms']);
        }
      }
    }

    return DictionaryEntry(
      word: json['word'] ?? '',
      phonetics: phonetics,
      audioUrl: audioUrl,
      partOfSpeech: partOfSpeech,
      definition: definition,
      synonyms: synonyms.isNotEmpty ? synonyms : null,
      examples: examples.isNotEmpty ? examples : null,
    );
  }
}

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  static Future<DictionaryEntry?> lookupWord(String word) async {
    try {
      // 単語をクリーンアップ（余分なスペースや記号を削除）
      final cleanWord = word.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '');
      
      if (cleanWord.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$cleanWord'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return DictionaryEntry.fromJson(data[0]);
        }
      }
      
      return null;
    } catch (e) {
      print('Dictionary lookup error: $e');
      return null;
    }
  }

  static Future<List<DictionaryEntry>> lookupMultipleMeanings(String word) async {
    try {
      final cleanWord = word.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '');
      
      if (cleanWord.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$cleanWord'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final List<DictionaryEntry> entries = [];
          final firstEntry = data[0];
          
          // 各品詞ごとにエントリーを作成
          if (firstEntry['meanings'] != null) {
            for (var meaning in firstEntry['meanings']) {
              if (meaning['definitions'] != null && meaning['definitions'].isNotEmpty) {
                String? phonetics;
                String? audioUrl;
                
                // 発音情報を取得
                if (firstEntry['phonetics'] != null && firstEntry['phonetics'].isNotEmpty) {
                  final phoneticsList = firstEntry['phonetics'] as List;
                  for (var phonetic in phoneticsList) {
                    if (phonetic['text'] != null) {
                      phonetics = phonetic['text'];
                    }
                    if (phonetic['audio'] != null && phonetic['audio'].toString().isNotEmpty) {
                      audioUrl = phonetic['audio'];
                    }
                    if (phonetics != null && audioUrl != null) break;
                  }
                }
                
                entries.add(DictionaryEntry(
                  word: firstEntry['word'] ?? word,
                  phonetics: phonetics,
                  audioUrl: audioUrl,
                  partOfSpeech: meaning['partOfSpeech'] ?? 'unknown',
                  definition: meaning['definitions'][0]['definition'] ?? 'No definition available',
                  synonyms: meaning['synonyms'] != null ? List<String>.from(meaning['synonyms']) : null,
                  examples: meaning['definitions'][0]['example'] != null 
                      ? [meaning['definitions'][0]['example']] 
                      : null,
                ));
              }
            }
          }
          
          return entries;
        }
      }
      
      return [];
    } catch (e) {
      print('Dictionary lookup error: $e');
      return [];
    }
  }
}