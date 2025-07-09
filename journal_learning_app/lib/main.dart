import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await StorageService.initializeSampleData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squirrel - Journal Language Learning',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
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
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildNavItem(index, item);
              }).toList(),
            ),
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppTheme.caption.copyWith(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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