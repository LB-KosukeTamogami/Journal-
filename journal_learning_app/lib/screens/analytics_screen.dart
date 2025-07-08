import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = '週間';
  Map<String, int> _analyticsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final data = await StorageService.getAnalyticsData();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('分析', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 統計カード
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: '連続記録',
                          value: (_analyticsData['currentStreak'] ?? 0).toString(),
                          unit: '日',
                          icon: Icons.local_fire_department,
                          color: AppTheme.warning,
                        ).animate().fadeIn().scale(delay: 100.ms),
                      ),
                const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: '総日記数',
                          value: (_analyticsData['totalEntries'] ?? 0).toString(),
                          unit: '件',
                          icon: Icons.book,
                          color: AppTheme.primaryBlue,
                        ).animate().fadeIn().scale(delay: 200.ms),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                      Expanded(
                        child: _StatCard(
                          title: '総単語数',
                          value: _formatWordCount(_analyticsData['totalWords'] ?? 0),
                          unit: '語',
                          icon: Icons.text_fields,
                          color: AppTheme.success,
                        ).animate().fadeIn().scale(delay: 300.ms),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: '習得単語',
                          value: (_analyticsData['learnedWords'] ?? 0).toString(),
                          unit: '個',
                          icon: Icons.school,
                          color: AppTheme.info,
                        ).animate().fadeIn().scale(delay: 400.ms),
                      ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 投稿頻度グラフ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '投稿頻度',
                  style: AppTheme.headline3,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final period in ['週間', '月間', '年間'])
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == period
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              period,
                              style: AppTheme.body2.copyWith(
                                color: _selectedPeriod == period
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontWeight: _selectedPeriod == period
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.borderColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.textPrimary,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            '${barSpot.y.toInt()}件',
                            AppTheme.body2.copyWith(
                              color: AppTheme.backgroundPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
                    handleBuiltInTouches: true,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const days = ['月', '火', '水', '木', '金', '土', '日'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2),
                        FlSpot(1, 3),
                        FlSpot(2, 1),
                        FlSpot(3, 4),
                        FlSpot(4, 3),
                        FlSpot(5, 2),
                        FlSpot(6, 3),
                      ],
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.backgroundPrimary,
                            strokeWidth: 2,
                            strokeColor: AppTheme.primaryBlue,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.3),
                            AppTheme.primaryBlue.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ).animate().fadeIn(delay: 500.ms),
            
            const SizedBox(height: 32),
            
            // 頻出単語・フレーズ
            Text(
              '頻出単語 TOP3',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: 16),
            _buildWordRanking(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWordRanking() {
    final words = [
      {'rank': 1, 'word': 'happy', 'count': 15},
      {'rank': 2, 'word': 'experience', 'count': 12},
      {'rank': 3, 'word': 'learning', 'count': 10},
    ];
    
    return Column(
      children: words.map((word) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRankColor(word['rank'] as int).withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getRankColor(word['rank'] as int).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${word['rank']}',
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getRankColor(word['rank'] as int),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    word['word'] as String,
                    style: AppTheme.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${word['count']}回',
                  style: AppTheme.body2,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
          delay: Duration(milliseconds: 600 + ((word['rank'] as int) - 1) * 100),
        ).slideX(begin: 0.2, end: 0);
      }).toList(),
    );
  }
  
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: AppTheme.headline3.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

