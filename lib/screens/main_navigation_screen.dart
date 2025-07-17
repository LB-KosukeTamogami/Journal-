import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'learning_screen.dart';
import 'analytics_screen.dart';
import 'my_page_screen.dart';
import '../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  static final GlobalKey<_MainNavigationScreenState> navigatorKey = GlobalKey<_MainNavigationScreenState>();
  
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
      // ジャーナル画面の場合、強制的に再構築
      if (index == 1) {
        // JournalScreenが再度initStateを呼ぶように、キーを変更
        _screens[1] = JournalScreen(key: UniqueKey());
      }
    });
  }

  List<Widget> _screens = [
    const HomeScreen(),
    const JournalScreen(),
    const LearningScreen(),
    const AnalyticsScreen(),
    const MyPageScreen(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(icon: Icons.home_rounded, label: 'ホーム'),
    NavigationItem(icon: Icons.book_rounded, label: 'ジャーナル'),
    NavigationItem(icon: Icons.school_rounded, label: '学習'),
    NavigationItem(icon: Icons.bar_chart_rounded, label: '分析'),
    NavigationItem(icon: Icons.person_rounded, label: 'マイページ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildNavItem(index, item);
                }).toList(),
              ),
            ),
            // ホームインジケーター用の余白
            SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 34 : 0),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavigationItem item) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  item.icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: AppTheme.caption.copyWith(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}