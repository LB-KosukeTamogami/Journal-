import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_creation_screen.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DiaryEntry> _allEntries = [];
  Map<DateTime, List<DiaryEntry>> _entriesByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await StorageService.getDiaryEntries();
      
      setState(() {
        _allEntries = entries;
        _entriesByDate = _groupEntriesByDate(entries);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<DiaryEntry>> _groupEntriesByDate(List<DiaryEntry> entries) {
    final groupedEntries = <DateTime, List<DiaryEntry>>{};
    
    for (final entry in entries) {
      final date = DateTime(
        entry.createdAt.year, 
        entry.createdAt.month, 
        entry.createdAt.day
      );
      
      if (groupedEntries[date] == null) {
        groupedEntries[date] = [];
      }
      groupedEntries[date]!.add(entry);
    }
    
    return groupedEntries;
  }

  List<DiaryEntry> _getJournalsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _entriesByDate[dateKey] ?? [];
  }

  List<Map<String, dynamic>> _getJournalsForCalendar(DateTime day) {
    final entries = _getJournalsForDay(day);
    return entries.map((entry) => {
      'id': entry.id,
      'title': entry.title,
      'content': entry.content,
      'date': entry.createdAt,
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('Journal', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                // TODO: 会話ジャーナルへの遷移
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // カレンダー
          Container(
            margin: const EdgeInsets.all(16),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: _getJournalsForCalendar,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: TextStyle(color: AppTheme.textSecondary),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryBlue, width: 2),
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTheme.headline3,
                leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textPrimary),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          ),
          
          const SizedBox(height: 16),
          
          // 選択された日の日記リスト
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _selectedDay == null
                    ? Center(
                        child: Text(
                          '日付を選択してください',
                          style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
                        ),
                      )
                    : _buildJournalList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.buttonShadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            _showJournalDialog(context);
          },
          backgroundColor: AppTheme.primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('新規作成', style: AppTheme.button),
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    final journals = _getJournalsForDay(_selectedDay!);
    
    if (journals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${DateFormat('M月d日').format(_selectedDay!)}の日記はまだありません',
              style: AppTheme.body1.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: journals.length,
      itemBuilder: (context, index) {
        final journal = journals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () {
              _showDiaryDetail(context, journal);
            },
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        journal.title,
                        style: AppTheme.headline3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(journal.createdAt),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  journal.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${journal.wordCount} words',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 50 * index),
            duration: 300.ms,
          ).slideX(begin: 0.1, end: 0),
        );
      },
    );
  }

  void _showJournalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '新しい日記を作成',
                style: AppTheme.headline2,
              ),
              const SizedBox(height: 24),
              
              // 日記作成ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiaryCreationScreen(),
                      ),
                    ).then((_) => _loadEntries());
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: Text(
                    '日記を書く',
                    style: AppTheme.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 会話ジャーナルボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: 会話ジャーナル機能の実装
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('会話ジャーナル機能は準備中です'),
                        backgroundColor: AppTheme.info,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
                  label: Text(
                    '会話ジャーナル',
                    style: AppTheme.button.copyWith(color: AppTheme.primaryBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiaryDetail(BuildContext context, DiaryEntry journal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          journal.title,
          style: AppTheme.headline3,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '作成日: ${DateFormat('yyyy/MM/dd').format(journal.createdAt)}',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 12),
              Text(
                journal.content,
                style: AppTheme.body2.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryCreationScreen(existingEntry: journal),
                ),
              ).then((_) => _loadEntries());
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }
}