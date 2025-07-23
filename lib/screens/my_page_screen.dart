import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/no_swipe_page_route.dart';
import 'auth/login_screen.dart';
import 'profile_edit_screen.dart';
import 'debug/supabase_status_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _currentPlan = 'ライトプラン';
  bool _notificationEnabled = true;
  String _notificationTime = '21:00';
  
  @override
  void initState() {
    super.initState();
    ThemeProvider.instance.addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  String get _userName {
    final user = AuthService.currentUser;
    return user?.userMetadata?['username'] ?? 'ゲスト';
  }
  
  String get _userEmail {
    final user = AuthService.currentUser;
    return user?.email ?? 'guest@example.com';
  }
  
  String get _userAvatar {
    final user = AuthService.currentUser;
    return user?.userMetadata?['avatar'] ?? 'person';
  }
  
  IconData _getAvatarIcon(String avatar) {
    switch (avatar) {
      case 'person':
        return Icons.person;
      case 'face':
        return Icons.face;
      case 'mood':
        return Icons.mood;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'pets':
        return Icons.pets;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      default:
        return Icons.person;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('マイページ', style: AppTheme.headline3),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プロフィールセクション
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Icon(
                        _getAvatarIcon(_userAvatar),
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '学習レベル: 中級',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // プロフィール編集ボタン
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        ).then((_) {
                          // 画面が戻ってきたときに再描画
                          setState(() {});
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('プロフィールを編集'),
                      style: AppButtonStyles.secondaryButton,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // プラン情報
            Container(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkColors.surface 
                : AppTheme.lightColors.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.star,
                      color: Colors.amber[700],
                    ),
                    title: Text('現在のプラン', style: AppTheme.body1),
                    subtitle: Text(_currentPlan, style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showPlanDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.book,
                      color: Colors.green,
                    ),
                    title: Text('製本申込履歴', style: AppTheme.body1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 製本申込履歴画面への遷移
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 設定セクション
            Container(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkColors.surface 
                : AppTheme.lightColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // テーマ設定
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '表示設定',
                      style: AppTheme.body1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      ThemeProvider.instance.getThemeModeIcon(),
                      color: AppTheme.primaryColor,
                    ),
                    title: Text('テーマ', style: AppTheme.body1),
                    subtitle: Text(ThemeProvider.instance.getThemeModeText(), style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showThemeSelectionDialog();
                    },
                  ),
                  const Divider(height: 1),
                  // 通知設定
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '通知設定',
                      style: AppTheme.body1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: Text('通知を有効にする', style: AppTheme.body1),
                    value: _notificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationEnabled = value;
                      });
                    },
                  ),
                  ListTile(
                    title: Text('通知時刻', style: AppTheme.body1),
                    subtitle: Text(_notificationTime, style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: _notificationEnabled,
                    onTap: _notificationEnabled ? () {
                      _showTimePickerDialog();
                    } : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // その他
            Container(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkColors.surface 
                : AppTheme.lightColors.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text('ヘルプ', style: AppTheme.body1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text('プライバシーポリシー', style: AppTheme.body1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text('利用規約', style: AppTheme.body1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.deepPurple),
                    title: Text('Supabase接続状態', style: AppTheme.body1),
                    subtitle: Text(
                      'デバッグ用：データ同期の確認',
                      style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupabaseStatusScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                    title: Text(
                      'サンプルデータを削除',
                      style: AppTheme.body1.copyWith(color: Colors.orange),
                    ),
                    subtitle: Text(
                      'デモ用のサンプルデータを削除します',
                      style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                    ),
                    onTap: () {
                      _showClearSampleDataDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'ログアウト',
                      style: AppTheme.body1.copyWith(color: Colors.red),
                    ),
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // バージョン情報
            Text(
              'Version 1.0.0',
              style: AppTheme.caption.copyWith(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  void _showPlanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.darkColors.surface 
            : AppTheme.lightColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'プランを選択',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: 20),
            _PlanOption(
              title: '無料プラン',
              price: '¥0',
              features: const ['日記記録', '翻訳機能', '広告あり'],
              isSelected: _currentPlan == '無料プラン',
              onTap: () {
                setState(() {
                  _currentPlan = '無料プラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _PlanOption(
              title: 'ライトプラン',
              price: '¥980/月',
              features: const ['AI添削', '暗記カード', '広告なし'],
              isSelected: _currentPlan == 'ライトプラン',
              isRecommended: true,
              onTap: () {
                setState(() {
                  _currentPlan = 'ライトプラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _PlanOption(
              title: 'プレミアムプラン',
              price: '¥2,980/月',
              features: const ['TTS機能', 'シャドウイング', '製本申込可能', '全機能利用可能'],
              isSelected: _currentPlan == 'プレミアムプラン',
              onTap: () {
                setState(() {
                  _currentPlan = 'プレミアムプラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_notificationTime.split(':')[0]),
        minute: int.parse(_notificationTime.split(':')[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _notificationTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  void _showThemeSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
              'テーマを選択',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
              'システム設定に従う',
              Icons.brightness_auto,
              ThemeMode.system,
            ),
            _buildThemeOption(
              'ライトモード',
              Icons.light_mode,
              ThemeMode.light,
            ),
            _buildThemeOption(
              'ダークモード',
              Icons.dark_mode,
              ThemeMode.dark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(String title, IconData icon, ThemeMode mode) {
    final isSelected = ThemeProvider.instance.themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: AppTheme.body1.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: AppTheme.primaryColor,
            )
          : null,
      onTap: () {
        ThemeProvider.instance.setThemeMode(mode);
        Navigator.pop(context);
        // ThemeProviderの変更を反映するために再描画
        setState(() {});
      },
    );
  }
  
  void _showClearSampleDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サンプルデータを削除'),
        content: const Text('デモ用のサンプルデータ（sample_で始まる日記と単語）を削除します。実際に作成したデータは削除されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await StorageService.clearSampleData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('サンプルデータを削除しました'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('削除に失敗しました: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await AuthService.signOut();
                
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    NoSwipePageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログアウトに失敗しました: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).primaryColor 
              : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkColors.surface 
              : AppTheme.lightColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTheme.body1.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'おすすめ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: AppTheme.headline3.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: AppTheme.body2,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkColors.textPrimary.withOpacity(0.05)
              : AppTheme.lightColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}