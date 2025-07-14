import 'package:flutter/material.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/storage_service.dart';
import '../../models/word.dart';
import '../../models/diary_entry.dart';

class SupabaseStatusScreen extends StatefulWidget {
  const SupabaseStatusScreen({super.key});

  @override
  State<SupabaseStatusScreen> createState() => _SupabaseStatusScreenState();
}

class _SupabaseStatusScreenState extends State<SupabaseStatusScreen> {
  bool _isLoading = false;
  String _status = 'Checking...';
  String _userId = 'Unknown';
  List<Word> _localWords = [];
  List<Word> _supabaseWords = [];
  List<dynamic> _localDiaries = [];
  List<dynamic> _supabaseDiaries = [];
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    try {
      // Supabase接続状態を確認
      final isAvailable = SupabaseService.isAvailable;
      _addLog('SupabaseService.isAvailable: $isAvailable');
      
      setState(() {
        _status = isAvailable ? 'Connected' : 'Not Connected';
      });

      if (isAvailable) {
        // ユーザーIDを取得
        final userId = await SupabaseService.getUserId();
        _addLog('User ID: $userId');
        setState(() {
          _userId = userId;
        });

        // Supabaseから単語を取得
        _addLog('Fetching words from Supabase...');
        final supabaseWords = await SupabaseService.getWords();
        _addLog('Got ${supabaseWords.length} words from Supabase');
        
        // Supabaseから日記を取得
        _addLog('Fetching diaries from Supabase...');
        final supabaseDiaries = await SupabaseService.getDiaryEntries();
        _addLog('Got ${supabaseDiaries.length} diaries from Supabase');
        
        setState(() {
          _supabaseWords = supabaseWords;
          _supabaseDiaries = supabaseDiaries;
        });
      }

      // ローカルから単語を取得
      _addLog('Fetching words from local storage...');
      final localWords = await _getLocalWords();
      _addLog('Got ${localWords.length} words from local storage');
      
      // ローカルから日記を取得
      _addLog('Fetching diaries from local storage...');
      final localDiaries = await _getLocalDiaries();
      _addLog('Got ${localDiaries.length} diaries from local storage');
      
      setState(() {
        _localWords = localWords;
        _localDiaries = localDiaries;
      });

    } catch (e) {
      _addLog('Error: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Word>> _getLocalWords() async {
    // ローカルストレージから直接単語を取得
    final jsonString = StorageService.prefs.getString('words');
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Word.fromJson(json)).toList();
  }

  Future<List<dynamic>> _getLocalDiaries() async {
    // ローカルストレージから直接日記を取得
    final jsonString = StorageService.prefs.getString('diary_entries');
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList;
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('[${DateTime.now().toIso8601String()}] $message');
    });
    print('[SupabaseDebug] $message');
  }

  Future<void> _syncFromSupabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Starting sync from Supabase...');
      
      // Supabaseから最新データを取得
      final words = await StorageService.getWords();
      _addLog('Sync completed. Got ${words.length} words');
      
      await _checkStatus(); // 状態を再確認
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同期が完了しました')),
      );
    } catch (e) {
      _addLog('Sync error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同期エラー: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    try {
      _addLog('Testing Supabase connection...');
      
      // 1. 接続状態を確認
      _addLog('1. Checking connection status...');
      final isAvailable = SupabaseService.isAvailable;
      _addLog('   isAvailable: $isAvailable');
      
      if (!isAvailable) {
        _addLog('   Connection not available. Stopping test.');
        return;
      }
      
      // 2. ユーザーIDを取得
      _addLog('2. Getting user ID...');
      final userId = await SupabaseService.getUserId();
      _addLog('   User ID: $userId');
      
      // 3. テストデータを作成して保存
      _addLog('3. Creating test diary entry...');
      final testEntry = DiaryEntry(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Entry',
        content: 'This is a test entry',
        translatedContent: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        wordCount: 5,
        learnedWords: [],
      );
      
      _addLog('4. Saving test entry to Supabase...');
      try {
        await SupabaseService.saveDiaryEntry(testEntry);
        _addLog('   ✓ Test entry saved successfully');
      } catch (e) {
        _addLog('   ✗ Failed to save test entry: $e');
      }
      
      // 4. 保存したデータを取得
      _addLog('5. Retrieving entries from Supabase...');
      try {
        final entries = await SupabaseService.getDiaryEntries();
        _addLog('   ✓ Retrieved ${entries.length} entries');
        
        // テストエントリーが含まれているか確認
        final hasTestEntry = entries.any((e) => e.id == testEntry.id);
        _addLog('   Test entry found: $hasTestEntry');
      } catch (e) {
        _addLog('   ✗ Failed to retrieve entries: $e');
      }
      
      _addLog('Test completed.');
      
    } catch (e, stack) {
      _addLog('Test error: $e');
      _addLog('Stack trace: $stack');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLocalData() async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全ローカルデータを削除'),
        content: const Text('本当にローカルの日記・単語データをすべて削除しますか？\n\nこれによりSupabaseのデータのみが使用されるようになります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Clearing all local data...');
      
      // ローカルの日記データを削除
      await StorageService.prefs.remove('diary_entries');
      _addLog('Local diary data cleared');
      
      // ローカルの単語データを削除
      await StorageService.prefs.remove('words');
      _addLog('Local word data cleared');
      
      await _checkStatus(); // 状態を再確認
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全ローカルデータを削除しました')),
      );
    } catch (e) {
      _addLog('Clear error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除エラー: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Supabase接続状態'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 接続状態
                  _buildSection(
                    title: '接続状態',
                    child: Row(
                      children: [
                        Icon(
                          _status == 'Connected' 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _status == 'Connected' 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _status,
                          style: AppTheme.body1.copyWith(
                            color: _status == 'Connected' 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ユーザー情報
                  _buildSection(
                    title: 'ユーザー情報',
                    child: Text(
                      'User ID: $_userId',
                      style: AppTheme.body2,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // データ統計
                  _buildSection(
                    title: 'データ統計',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ローカル単語数: ${_localWords.length}',
                          style: AppTheme.body2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supabase単語数: ${_supabaseWords.length}',
                          style: AppTheme.body2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ローカル日記数: ${_localDiaries.length}',
                          style: AppTheme.body2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supabase日記数: ${_supabaseDiaries.length}',
                          style: AppTheme.body2,
                        ),
                        if (_localWords.length != _supabaseWords.length || 
                            _localDiaries.length != _supabaseDiaries.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠️ データ数が一致しません',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // アクションボタン
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('状態を更新'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _syncFromSupabase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Supabaseから強制同期'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _clearLocalData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('全ローカルデータを削除'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // テストボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _testSupabaseConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.info,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Supabase接続テスト'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // デバッグログ
                  _buildSection(
                    title: 'デバッグログ',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _debugLogs.map((log) => Text(
                            log,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headline3,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}