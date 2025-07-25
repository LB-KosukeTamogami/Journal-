import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as Math;
import 'diary_creation_screen.dart';
import 'diary_detail_screen.dart';
import 'conversation_journal_screen.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DiaryEntry> _allEntries = [];
  Map<DateTime, List<DiaryEntry>> _entriesByDate = {};
  bool _isLoading = true;
  bool _isCalendarExpanded = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEntries();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 180,
      end: 400, // カレンダーの展開時の推定高さ
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // 初期状態が縮小なのでアニメーションを初期状態に
    // _animationController.forward();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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
    
    // 各日付の日記を時間の降順でソート（新しい順）
    groupedEntries.forEach((date, entries) {
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    
    return groupedEntries;
  }

  List<DiaryEntry> _getJournalsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _entriesByDate[dateKey] ?? [];
  }

  // 次の月が未来でないかチェック
  bool _canGoToNextMonth(DateTime focusedDay) {
    final now = DateTime.now();
    final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1, 1);
    return nextMonth.isBefore(DateTime(now.year, now.month + 1, 1));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('ジャーナル'),
      ),
      body: Column(
        children: [
          // カレンダー
          AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return Container(
                height: _heightAnimation.value,
                margin: const EdgeInsets.all(16),
                child: Stack(
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TableCalendar<Map<String, dynamic>>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.now(),
                          focusedDay: _focusedDay,
                          calendarFormat: _isCalendarExpanded ? CalendarFormat.month : CalendarFormat.week,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          eventLoader: _getJournalsForCalendar,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            weekendTextStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                            disabledTextStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                            ),
                            markerDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: Theme.of(context).textTheme.displaySmall ?? AppTheme.headline3,
                            leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).textTheme.bodyLarge?.color),
                            rightChevronIcon: Icon(
                              Icons.chevron_right, 
                              color: _canGoToNextMonth(_focusedDay) 
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3),
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            // 未来日の選択を制限
                            if (selectedDay.isAfter(DateTime.now())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('未来の日付は選択できません'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            // 未来月への移動を制限
                            final now = DateTime.now();
                            if (focusedDay.year > now.year || 
                                (focusedDay.year == now.year && focusedDay.month > now.month)) {
                              return;
                            }
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 展開/折りたたみボタンを右下に配置
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isCalendarExpanded = !_isCalendarExpanded;
                          if (_isCalendarExpanded) {
                            _animationController.forward();
                          } else {
                            _animationController.reverse();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: _isCalendarExpanded ? 0 : 0.5,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.expand_less,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              ),
            );
            },
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // 選択された日の日記リスト
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : _selectedDay == null
                    ? Center(
                        child: Text(
                          '日付を選択してください',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      )
                    : _buildJournalList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            // 選択された日付が未来日でないことを確認
            if (_selectedDay != null && _selectedDay!.isAfter(DateTime.now())) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('未来の日付には日記を作成できません'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              return;
            }
            
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiaryCreationScreen(),
              ),
            );
            
            // 日記作成完了後、最新データを再読み込み
            if (result == true) {
              await _loadEntries();
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('新規作成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    final journals = _getJournalsForDay(_selectedDay!);
    
    if (journals.isEmpty) {
      return Container(
        padding: const EdgeInsets.only(bottom: 80), // FABの高さを考慮して調整
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '${DateFormat('M月d日').format(_selectedDay!)}の日記はまだありません',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 8),
              Text(
                '右下のボタンから日記を作成できます',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // グラデーションマスクを使用して境界を曖昧にする
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
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
                          style: Theme.of(context).textTheme.displaySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(journal.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    journal.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${journal.wordCount} words',
                        style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }

  // 不要になったため削除
  /*void _showJournalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
              const SizedBox(height: 16),
              
              // 日記作成カード
              AppCard(
                onTap: () async {
                  Navigator.pop(context);
                  print('[JournalScreen] Navigating to DiaryCreationScreen');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryCreationScreen(),
                    ),
                  );
                  print('[JournalScreen] Returned from diary creation/review, result: $result');
                  _loadEntries();
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '日記を書く',
                            style: AppTheme.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '今日の出来事を記録しましょう',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textTertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 会話ジャーナルカード
              AppCard(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationJournalScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.info,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '会話ジャーナル',
                            style: AppTheme.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '会話を通じて英語を学びましょう',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textTertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  }*/

  void _showDiaryDetail(BuildContext context, DiaryEntry journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(entry: journal),
      ),
    ).then((updated) {
      if (updated != null) {
        _loadEntries();
      }
    });
  }
}