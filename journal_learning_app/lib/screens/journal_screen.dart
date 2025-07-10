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

class _JournalScreenState extends State<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DiaryEntry> _allEntries = [];
  Map<DateTime, List<DiaryEntry>> _entriesByDate = {};
  bool _isLoading = true;
  bool _isCalendarExpanded = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEntries();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
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
        title: Text('ジャーナル', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConversationJournalScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.secondaryColor,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isCalendarExpanded ? null : 320,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _isCalendarExpanded ? CalendarFormat.month : CalendarFormat.week,
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
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
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
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 展開/折りたたみボタンを右下に配置
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isCalendarExpanded = !_isCalendarExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundPrimary.withOpacity(0.9),
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
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          ),
          
          const SizedBox(height: 16),
          
          // 選択された日の日記リスト
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiaryCreationScreen(),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
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
    
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // スクロール位置に応じてカードの表示状態を更新
        if (scrollNotification is ScrollUpdateNotification) {
          setState(() {});
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: journals.length,
        itemBuilder: (context, index) {
          final journal = journals[index];
          return AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              // スクロール位置に基づいてカードの不透明度とスケールを計算
              double opacity = 1.0;
              double scale = 1.0;
              double translateY = 0.0;
              
              if (_scrollController.hasClients) {
                final itemHeight = 140.0; // カードの推定高さ
                final itemPosition = index * itemHeight;
                final scrollOffset = _scrollController.offset;
                final viewportHeight = _scrollController.position.viewportDimension;
                
                // カードの画面上での位置
                final cardTopPosition = itemPosition - scrollOffset;
                final cardBottomPosition = cardTopPosition + itemHeight;
                
                // カードが画面上部から消える時のアニメーション（グラデーション効果）
                if (cardBottomPosition < 150) {
                  final fadeDistance = 150.0;
                  opacity = (cardBottomPosition / fadeDistance).clamp(0.0, 1.0);
                  // より緩やかなフェード曲線
                  opacity = Math.pow(opacity, 0.7).toDouble();
                  scale = 0.98 + (0.02 * opacity);
                  translateY = -10.0 * (1.0 - opacity);
                }
                
                // カードが画面下部から現れる時のアニメーション
                if (cardTopPosition > viewportHeight - 150) {
                  final fadeDistance = 150.0;
                  final distanceFromBottom = cardTopPosition - (viewportHeight - 150);
                  opacity = (1.0 - (distanceFromBottom / fadeDistance)).clamp(0.0, 1.0);
                  // より緩やかなフェード曲線
                  opacity = Math.pow(opacity, 0.7).toDouble();
                  scale = 0.98 + (0.02 * opacity);
                }
              }
              
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: Container(
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
                    ),
                  ),
                ),
              );
            },
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
              const SizedBox(height: 16),
              
              // 日記作成カード
              AppCard(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiaryCreationScreen(),
                    ),
                  ).then((_) => _loadEntries());
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
// Force rebuild
